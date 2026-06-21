import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/anime_spot.dart';

/// Hono バックエンド（anitrail-back）の /animes・/spots を叩くクライアント。
/// /spots は Bearer 認証必須なので Supabase セッションのトークンを付与する。
class SpotApi {
  SpotApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static final Map<String, ({DateTime cachedAt, Future<List<Spot>> request})>
  _spotsCache = {};
  static final Map<String, StampCard> _stampCardSnapshots = {};
  static final Map<String, ({DateTime cachedAt, Future<StampCard> request})>
  _stampCardRequests = {};

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
        .map((e) => StampCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 起動時表示用の保存済みしおり一覧。通信は行わない。
  Future<List<StampCard>> readCachedStampCards() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stampCardListCacheKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => StampCard.fromJson(item as Map<String, dynamic>))
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
  }

  Future<void> _clearStampCardListCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stampCardListCacheKey);
  }

  /// 指定しおり（カード）でスタンプ取得済みの spot_id 集合を返す。
  Future<Set<String>> fetchVisitedSpotIds(String cardId) async {
    final token = _accessToken;
    final res = await _client.get(
      Uri.parse('$_baseUrl/stamp-cards/$cardId/stamps'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) return {};
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final list = (body['data'] as List? ?? []);
    return list
        .map((e) => (e as Map<String, dynamic>)['spot_id'] as String?)
        .whereType<String>()
        .toSet();
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
