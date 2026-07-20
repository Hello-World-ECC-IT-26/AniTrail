import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/api_http_client.dart';
import '../models/anime_spot.dart';

/// Hono バックエンド（anitrail-back）の /animes・/spots を叩くクライアント。
/// /spots は Bearer 認証必須なので Supabase セッションのトークンを付与する。
class SpotApi {
  SpotApi({http.Client? client}) : _client = client ?? ApiHttpClient.shared;

  final http.Client _client;
  static final Map<String, ({DateTime cachedAt, Future<List<Spot>> request})>
  _spotsCache = {};
  static final Map<String, StampCard> _stampCardSnapshots = {};
  static final Map<String, ({DateTime cachedAt, Future<StampCard> request})>
  _stampCardRequests = {};
  static final Map<
    String,
    ({DateTime cachedAt, Future<List<AnimeResult>> request})
  >
  _animeSearchRequests = {};
  static final Map<String, ({DateTime cachedAt, Future<List<String>> request})>
  _suggestionRequests = {};
  static final Map<String, Future<Map<String, dynamic>>> _bootstrapRequests =
      {};
  static final Map<
    String,
    ({DateTime cachedAt, Future<List<StampCollection>> request})
  >
  _collectionRequests = {};

  String _stampCardCacheKey(String cardId) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';
    return '$userId:$cardId';
  }

  String get _stampCardListCacheKey {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';
    return 'stamp_card_list:$userId';
  }

  String get _baseUrl {
    final url = dotenv.env['API_BASE_URL'];
    if (url == null || url.isEmpty) {
      throw StateError('API_BASE_URL が .env に設定されていません');
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  String? get _accessToken =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  /// アニメ名で検索（部分一致）。各件に spot_count を含む。
  Future<List<AnimeResult>> searchAnimes(String query) async {
    final normalized = '$_userCacheScope:${query.trim().toLowerCase()}';
    final cached = _animeSearchRequests[normalized];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <
            const Duration(minutes: 5)) {
      return cached.request;
    }
    final request = _searchAnimes(query.trim());
    _animeSearchRequests[normalized] = (
      cachedAt: DateTime.now(),
      request: request,
    );
    try {
      return await request;
    } catch (_) {
      _animeSearchRequests.remove(normalized);
      rethrow;
    }
  }

  Future<List<AnimeResult>> _searchAnimes(String query) async {
    final uri = Uri.parse(
      '$_baseUrl/animes',
    ).replace(queryParameters: {'title': query});
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('アニメ検索に失敗しました (${res.statusCode})');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final list = (body['data'] as List? ?? []);
    return list
        .map(
          (e) => AnimeResult.fromJson(
            e as Map<String, dynamic>,
            baseUrl: _baseUrl,
          ),
        )
        .toList();
  }

  /// 入力中の検索候補。外部アニメAPIを呼ばない軽量エンドポイントを使う。
  Future<List<String>> searchAnimeSuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    final normalized = '$_userCacheScope:${trimmed.toLowerCase()}';
    final cached = _suggestionRequests[normalized];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <
            const Duration(minutes: 10)) {
      return cached.request;
    }
    final request = _searchAnimeSuggestions(trimmed);
    _suggestionRequests[normalized] = (
      cachedAt: DateTime.now(),
      request: request,
    );
    try {
      return await request;
    } catch (_) {
      _suggestionRequests.remove(normalized);
      rethrow;
    }
  }

  Future<List<String>> _searchAnimeSuggestions(String trimmed) async {
    final uri = Uri.parse(
      '$_baseUrl/animes/summary',
    ).replace(queryParameters: {'title': trimmed});
    final res = await _client.get(uri);
    if (res.statusCode != 200) return [];

    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final list = body['data'] as List? ?? [];
    return list
        .map((item) => (item as Map<String, dynamic>)['title'] as String?)
        .whereType<String>()
        .where((title) => title.isNotEmpty)
        .toSet()
        .take(8)
        .toList();
  }

  Future<bool> isBookmarked(String spotId) async {
    final token = _accessToken;
    final response = await _client.get(
      Uri.parse('$_baseUrl/bookmarks'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) return false;
    final data = jsonDecode(response.body)['data'] as List<dynamic>;
    return data.any((b) => b['spot_id'].toString() == spotId);
  }

  Future<void> addBookmark(String spotId) async {
    final token = _accessToken;
    await _client.post(
      Uri.parse('$_baseUrl/bookmarks'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'spot_id': spotId}),
    );
  }

  /// 聖地の投稿写真一覧を取得（Street View の前に置かない — 呼び出し側で先頭に SV を追加する）
  Future<List<String>> fetchSpotPostUrls(String spotId) async {
    final uri = Uri.parse(
      '$_baseUrl/spot-posts',
    ).replace(queryParameters: {'spot_id': spotId, 'limit': '10'});
    final res = await _client.get(uri);
    if (res.statusCode != 200) return [];
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final list = (body['data'] as List? ?? []);
    return list
        .map((e) => e['image_url'] as String?)
        .whereType<String>()
        .toList();
  }

  Future<SpotDetailPayload> fetchSpotDetail(String spotId) async {
    final token = _accessToken;
    final res = await _client.get(
      Uri.parse('$_baseUrl/spots/$spotId/detail'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('聖地詳細の取得に失敗しました (${res.statusCode})');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return SpotDetailPayload(
      spot: Spot.fromJson(
        data['spot'] as Map<String, dynamic>,
        baseUrl: _baseUrl,
      ),
      photoUrls: (data['photo_urls'] as List? ?? const [])
          .whereType<String>()
          .toList(),
      comments: (data['comments'] as List? ?? const [])
          .map((item) => SpotComment.fromJson(item as Map<String, dynamic>))
          .toList(),
      canPostComment: data['can_post_comment'] as bool? ?? false,
      visited: data['visited'] as bool? ?? false,
      bookmarked: data['bookmarked'] as bool? ?? false,
    );
  }

  /// 聖地に寄せられた公開コメントを新しい順で取得する。
  Future<SpotCommentsPayload> fetchSpotComments(String spotId) async {
    final uri = Uri.parse(
      '$_baseUrl/spot-comments',
    ).replace(queryParameters: {'spot_id': spotId, 'limit': '50'});
    final token = _accessToken;
    final res = await _client.get(
      uri,
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('コメントの取得に失敗しました (${res.statusCode})');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final list = body['data'] as List? ?? [];
    final comments = list
        .map((item) => SpotComment.fromJson(item as Map<String, dynamic>))
        .toList();
    return SpotCommentsPayload(
      comments: comments,
      canPost: body['can_post'] as bool? ?? false,
    );
  }

  /// 現在のユーザーが、指定聖地へコメントを投稿できるかを返す。
  Future<bool> canPostSpotComment(String spotId) async {
    final token = _accessToken;
    if (token == null) return false;
    final uri = Uri.parse(
      '$_baseUrl/spot-comments/permission',
    ).replace(queryParameters: {'spot_id': spotId});
    final res = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) return false;
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return body['can_post'] as bool? ?? false;
  }

  /// 訪問済みの聖地へコメントを投稿する。
  Future<SpotComment> createSpotComment({
    required String spotId,
    required String comment,
  }) async {
    final token = _accessToken;
    final res = await _client.post(
      Uri.parse('$_baseUrl/spot-comments'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'spot_id': spotId, 'comment': comment}),
    );
    if (res.statusCode != 200) {
      String detail = '';
      try {
        final body =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        detail = body['error']?.toString() ?? '';
      } catch (_) {
        detail = utf8.decode(res.bodyBytes);
      }
      throw Exception(
        'コメントの投稿に失敗しました (${res.statusCode})'
        '${detail.isEmpty ? '' : ': $detail'}',
      );
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return SpotComment.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// 自分が投稿したコメントを削除する。
  Future<void> deleteSpotComment(String commentId) async {
    final token = _accessToken;
    if (token == null) throw StateError('ログインが必要です');

    final res = await _client.delete(
      Uri.parse('$_baseUrl/spot-comments/$commentId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) return;

    String detail = '';
    try {
      final body =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      detail = body['error']?.toString() ?? '';
    } catch (_) {
      detail = utf8.decode(res.bodyBytes);
    }
    throw Exception(
      'コメントを削除できませんでした (${res.statusCode})'
      '${detail.isEmpty ? '' : ': $detail'}',
    );
  }

  Future<void> removeBookmark(String spotId) async {
    final token = _accessToken;
    await _client.delete(
      Uri.parse('$_baseUrl/bookmarks/$spotId'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
  }

  /// しおり（type:'custom' のスタンプカード）を作成。成功時に card_id を返す。
  Future<String?> createStampCard({
    String? title,
    required List<String> spotIds,
  }) async {
    final token = _accessToken;
    final res = await _client.post(
      Uri.parse('$_baseUrl/stamp-cards'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'type': 'custom',
        if (title != null && title.isNotEmpty) 'title': title,
        'spot_ids': spotIds,
      }),
    );
    if (res.statusCode != 200) {
      String detail = '';
      try {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        detail = body is Map ? (body['error']?.toString() ?? '') : '';
      } catch (_) {
        detail = utf8.decode(res.bodyBytes);
      }
      throw Exception(
        'しおりの作成に失敗しました (${res.statusCode})'
        '${detail.isEmpty ? '' : ': $detail'}',
      );
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    await _clearStampCardListCache();
    return data?['card_id'] as String?;
  }

  /// ユーザーの作成済みしおり（スタンプカード）一覧を取得。
  Future<List<StampCard>> fetchStampCards() async {
    final token = _accessToken;
    final res = await _client.get(
      Uri.parse('$_baseUrl/stamp-cards'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('しおり一覧の取得に失敗しました (${res.statusCode})');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final list = (body['data'] as List? ?? []);
    final prefs = await SharedPreferences.getInstance();
    unawaited(prefs.setString(_stampCardListCacheKey, jsonEncode(list)));
    return list
        .map(
          (e) =>
              StampCard.fromJson(e as Map<String, dynamic>, baseUrl: _baseUrl),
        )
        .toList();
  }

  String get _userCacheScope =>
      Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';

  Future<Map<String, dynamic>> fetchAppBootstrap() {
    final scope = _userCacheScope;
    return _bootstrapRequests.putIfAbsent(scope, () async {
      try {
        final token = _accessToken;
        final res = await _client.get(
          Uri.parse('$_baseUrl/app/bootstrap'),
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        );
        if (res.statusCode != 200) {
          throw Exception('ホーム情報の取得に失敗しました (${res.statusCode})');
        }
        final body =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        unawaited(prefs.setString('app_bootstrap:v1:$scope', jsonEncode(data)));
        return data;
      } finally {
        _bootstrapRequests.remove(scope);
      }
    });
  }

  Future<Map<String, dynamic>?> readCachedAppBootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('app_bootstrap:v1:$_userCacheScope');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      await prefs.remove('app_bootstrap:v1:$_userCacheScope');
      return null;
    }
  }

  Future<List<StampCollection>> fetchStampCollections({
    bool force = false,
  }) async {
    final scope = _userCacheScope;
    final cached = _collectionRequests[scope];
    if (!force &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) <
            const Duration(seconds: 15)) {
      return cached.request;
    }
    final request = _fetchStampCollections();
    _collectionRequests[scope] = (cachedAt: DateTime.now(), request: request);
    try {
      return await request;
    } catch (_) {
      _collectionRequests.remove(scope);
      rethrow;
    }
  }

  Future<List<StampCollection>> _fetchStampCollections() async {
    final token = _accessToken;
    final res = await _client.get(
      Uri.parse('$_baseUrl/stamp-collections'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('コレクションの取得に失敗しました (${res.statusCode})');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return (body['data'] as List? ?? const [])
        .map(
          (item) => StampCollection.fromJson(
            item as Map<String, dynamic>,
            baseUrl: _baseUrl,
          ),
        )
        .toList();
  }

  Future<void> clearUserCaches() async {
    final scope = _userCacheScope;
    _bootstrapRequests.remove(scope);
    _collectionRequests.remove(scope);
    final prefs = await SharedPreferences.getInstance();
    for (final key
        in prefs.getKeys().where((key) => key.contains(scope)).toList()) {
      await prefs.remove(key);
    }
  }

  /// 起動時表示用の保存済みしおり一覧。通信は行わない。
  Future<List<StampCard>> readCachedStampCards() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stampCardListCacheKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (item) => StampCard.fromJson(
              item as Map<String, dynamic>,
              baseUrl: _baseUrl,
            ),
          )
          .toList();
    } catch (_) {
      await prefs.remove(_stampCardListCacheKey);
      return [];
    }
  }

  /// 保存済みの詳細があれば即時に返す。通信は行わない。
  Future<StampCard?> readCachedStampCard(String cardId) async {
    final key = _stampCardCacheKey(cardId);
    final memory = _stampCardSnapshots[key];
    if (memory != null) return memory;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('stamp_card_detail:$key');
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final card = StampCard.fromJson(json, baseUrl: _baseUrl);
      _stampCardSnapshots[key] = card;
      return card;
    } catch (_) {
      await prefs.remove('stamp_card_detail:$key');
      return null;
    }
  }

  /// 指定したしおりと、選択順を保った行き先一覧を取得する。
  Future<StampCard> fetchStampCard(String cardId) async {
    final key = _stampCardCacheKey(cardId);
    final cachedRequest = _stampCardRequests[key];
    if (cachedRequest != null &&
        DateTime.now().difference(cachedRequest.cachedAt) <
            const Duration(minutes: 5)) {
      return cachedRequest.request;
    }

    final request = _fetchStampCard(cardId, key);
    _stampCardRequests[key] = (cachedAt: DateTime.now(), request: request);
    try {
      return await request;
    } catch (_) {
      _stampCardRequests.remove(key);
      rethrow;
    }
  }

  Future<StampCard> _fetchStampCard(String cardId, String cacheKey) async {
    final token = _accessToken;
    final res = await _client.get(
      Uri.parse('$_baseUrl/stamp-cards/$cardId'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('しおり詳細の取得に失敗しました (${res.statusCode})');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('しおりが見つかりません');
    final card = StampCard.fromJson(data, baseUrl: _baseUrl);
    _stampCardSnapshots[cacheKey] = card;
    final prefs = await SharedPreferences.getInstance();
    unawaited(prefs.setString('stamp_card_detail:$cacheKey', jsonEncode(data)));
    return card;
  }

  /// ホーム表示中に詳細を先読みする。
  Future<void> prefetchStampCards(Iterable<String> cardIds) async {
    await Future.wait(
      cardIds.map((id) async {
        try {
          await fetchStampCard(id);
        } catch (_) {
          // 先読み失敗は、詳細画面の通常リトライに委ねる。
        }
      }),
    );
  }

  Future<void> updateStampCardTitle(String cardId, String title) async {
    final token = _accessToken;
    final res = await _client.patch(
      Uri.parse('$_baseUrl/stamp-cards/$cardId'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'title': title}),
    );
    if (res.statusCode != 200) {
      throw Exception('しおりの編集に失敗しました (${res.statusCode})');
    }
    await _clearStampCardCache(cardId);
  }

  Future<void> deleteStampCard(String cardId) async {
    final token = _accessToken;
    final res = await _client.delete(
      Uri.parse('$_baseUrl/stamp-cards/$cardId'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('しおりの削除に失敗しました (${res.statusCode})');
    }
    await _clearStampCardCache(cardId);
  }

  Future<void> _clearStampCardCache(String cardId) async {
    final key = _stampCardCacheKey(cardId);
    _stampCardSnapshots.remove(key);
    _stampCardRequests.remove(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('stamp_card_detail:$key');
    await prefs.remove(_stampCardListCacheKey);
    await _invalidateAggregateCaches();
  }

  Future<void> _clearStampCardListCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stampCardListCacheKey);
    await _invalidateAggregateCaches();
  }

  Future<void> _invalidateAggregateCaches() async {
    final scope = _userCacheScope;
    _bootstrapRequests.remove(scope);
    _collectionRequests.remove(scope);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_bootstrap:v1:$scope');
  }

  /// 指定しおり（カード）でスタンプ取得済みの spot_id 集合を返す。
  Future<Set<String>> fetchVisitedSpotIds(String cardId) async {
    final stats = await fetchStampVisitStats(cardId);
    return stats.keys.toSet();
  }

  /// ログインユーザーが獲得したスタンプ履歴の総数を返す。
  Future<int> fetchCollectedStampCount() async {
    final token = _accessToken;
    final res = await _client.get(
      Uri.parse('$_baseUrl/stamps/count'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('スタンプ数の取得に失敗しました (${res.statusCode})');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return (body['count'] as num?)?.toInt() ?? 0;
  }

  /// 訪問履歴をスポット単位の回数・最終訪問日時に集計する。
  Future<Map<String, StampVisitStats>> fetchStampVisitStats(
    String cardId,
  ) async {
    final token = _accessToken;
    final res = await _client.get(
      Uri.parse('$_baseUrl/stamp-cards/$cardId/stamps'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) return const {};
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final list = (body['data'] as List? ?? []);
    final stats = <String, StampVisitStats>{};
    for (final value in list) {
      final row = value as Map<String, dynamic>;
      final spotId = row['spot_id'] as String?;
      if (spotId == null) continue;
      final obtainedAt = DateTime.tryParse(row['obtained_at'] as String? ?? '');
      final arrivalPhotoUrl = row['arrival_photo_url'] as String?;
      final current = stats[spotId];
      final currentDate = current?.lastVisitedAt;
      final photoUrls = {
        ...?current?.arrivalPhotoUrls,
        if (arrivalPhotoUrl != null && arrivalPhotoUrl.isNotEmpty)
          arrivalPhotoUrl,
      }.toList();
      stats[spotId] = StampVisitStats(
        count: (current?.count ?? 0) + 1,
        lastVisitedAt: currentDate == null
            ? obtainedAt
            : obtainedAt == null || currentDate.isAfter(obtainedAt)
            ? currentDate
            : obtainedAt,
        arrivalPhotoUrls: photoUrls,
      );
    }
    return stats;
  }

  Future<String> createStamp({
    required String cardId,
    required String spotId,
  }) async {
    final token = _accessToken;
    final res = await _client.post(
      Uri.parse('$_baseUrl/stamps'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'card_id': cardId, 'spot_id': spotId}),
    );
    if (res.statusCode != 200) {
      String detail = '';
      try {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        detail = body is Map ? (body['error']?.toString() ?? '') : '';
      } catch (_) {
        detail = utf8.decode(res.bodyBytes);
      }
      throw Exception(
        'スタンプの記録に失敗しました (${res.statusCode})'
        '${detail.isEmpty ? '' : ': $detail'}',
      );
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    final stampId = data['stamp_id'] as String?;
    if (stampId == null || stampId.isEmpty) {
      throw Exception('作成したスタンプIDを取得できませんでした');
    }
    await _clearStampCardCache(cardId);
    return stampId;
  }

  Future<String> uploadArrivalPhoto({
    required String spotId,
    required String stampId,
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) async {
    final resolvedContentType = _resolveImageContentType(
      filename: filename,
      bytes: bytes,
      mimeType: contentType,
    );
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/spot-posts'),
    );
    final token = _accessToken;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields['spot_id'] = spotId;
    request.fields['stamp_id'] = stampId;
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: _ensureImageFilename(filename, resolvedContentType),
        contentType: MediaType.parse(resolvedContentType),
      ),
    );
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      String detail = '';
      try {
        final errorBody =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final error = errorBody['error']?.toString() ?? '';
        final code = errorBody['code']?.toString() ?? '';
        detail = [
          if (error.isNotEmpty) error,
          if (code.isNotEmpty) code,
        ].join(' / ');
      } catch (_) {
        detail = utf8.decode(response.bodyBytes);
      }
      throw Exception(
        '到着写真の保存に失敗しました (${response.statusCode})'
        '${detail.isEmpty ? '' : ': $detail'}',
      );
    }
    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return data['image_url'] as String;
  }

  String _resolveImageContentType({
    required String filename,
    required List<int> bytes,
    String? mimeType,
  }) {
    final normalized = mimeType?.trim().toLowerCase();
    if (_isSupportedImageMime(normalized)) return normalized!;

    final detected = lookupMimeType(
      filename,
      headerBytes: bytes,
    )?.toLowerCase();
    if (_isSupportedImageMime(detected)) return detected!;

    return 'image/jpeg';
  }

  bool _isSupportedImageMime(String? mimeType) {
    return mimeType == 'image/jpeg' ||
        mimeType == 'image/png' ||
        mimeType == 'image/webp' ||
        mimeType == 'image/gif';
  }

  String _ensureImageFilename(String filename, String contentType) {
    final extension = switch (contentType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/gif' => 'gif',
      _ => 'jpg',
    };
    return 'arrival_photo.$extension';
  }

  /// 指定アニメの聖地一覧。lat/lng 指定で距離（distance_m）付き・距離昇順。
  Future<List<Spot>> fetchSpots(
    String animeId, {
    double? lat,
    double? lng,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';
    final cacheKey = '$userId:$animeId:${lat ?? ''}:${lng ?? ''}';
    final cached = _spotsCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <
            const Duration(minutes: 1)) {
      return cached.request;
    }

    final request = _fetchSpots(animeId, lat: lat, lng: lng);
    _spotsCache[cacheKey] = (cachedAt: DateTime.now(), request: request);
    try {
      return await request;
    } catch (_) {
      _spotsCache.remove(cacheKey);
      rethrow;
    }
  }

  Future<List<Spot>> _fetchSpots(
    String animeId, {
    double? lat,
    double? lng,
  }) async {
    final params = <String, String>{'anime_id': animeId};
    if (lat != null && lng != null) {
      params['lat'] = '$lat';
      params['lng'] = '$lng';
    }
    final uri = Uri.parse('$_baseUrl/spots').replace(queryParameters: params);

    final token = _accessToken;
    final res = await _client.get(
      uri,
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('聖地の取得に失敗しました (${res.statusCode})');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final list = (body['data'] as List? ?? []);
    return list
        .map((e) => Spot.fromJson(e as Map<String, dynamic>, baseUrl: _baseUrl))
        .toList();
  }
}

class SpotComment {
  final String id;
  final String spotId;
  final String userId;
  final String? username;
  final String? avatarUrl;
  final String? imageUrl;
  final bool? _canDelete;
  final String comment;
  final DateTime? createdAt;

  bool get canDelete => _canDelete ?? false;

  const SpotComment({
    required this.id,
    required this.spotId,
    required this.userId,
    this.username,
    this.avatarUrl,
    this.imageUrl,
    bool? canDelete,
    required this.comment,
    this.createdAt,
  }) : _canDelete = canDelete;

  factory SpotComment.fromJson(Map<String, dynamic> json) => SpotComment(
    id: json['id'] as String,
    spotId: json['spot_id'] as String,
    userId: json['user_id'] as String,
    username: json['username'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    imageUrl: json['image_url'] as String?,
    canDelete: json['can_delete'] as bool? ?? false,
    comment: json['comment'] as String? ?? '',
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );
}

class SpotCommentsPayload {
  final List<SpotComment> comments;
  final bool canPost;

  const SpotCommentsPayload({required this.comments, required this.canPost});
}

class SpotDetailPayload {
  final Spot spot;
  final List<String> photoUrls;
  final List<SpotComment> comments;
  final bool canPostComment;
  final bool visited;
  final bool bookmarked;

  const SpotDetailPayload({
    required this.spot,
    required this.photoUrls,
    required this.comments,
    required this.canPostComment,
    required this.visited,
    required this.bookmarked,
  });
}
