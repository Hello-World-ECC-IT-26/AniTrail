import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/anime_spot.dart';

/// Hono バックエンド（anitrail-back）の /animes・/spots を叩くクライアント。
/// /spots は Bearer 認証必須なので Supabase セッションのトークンを付与する。
class SpotApi {
  SpotApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

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
    final uri = Uri.parse('$_baseUrl/animes').replace(
      queryParameters: {'title': query},
    );
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('アニメ検索に失敗しました (${res.statusCode})');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final list = (body['data'] as List? ?? []);
    return list
        .map((e) => AnimeResult.fromJson(e as Map<String, dynamic>, baseUrl: _baseUrl))
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
    final uri = Uri.parse('$_baseUrl/spot-posts').replace(
      queryParameters: {'spot_id': spotId, 'limit': '10'},
    );
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

  /// 指定アニメの聖地一覧。lat/lng 指定で距離（distance_m）付き・距離昇順。
  Future<List<Spot>> fetchSpots(
    String animeId, {
    double? lat,
    double? lng,
  }) async {
    final params = <String, String>{'anime_id': animeId};
    if (lat != null && lng != null) {
      params['lat'] = '$lat';
      params['lng'] = '$lng';
    }
    final uri =
        Uri.parse('$_baseUrl/spots').replace(queryParameters: params);

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
