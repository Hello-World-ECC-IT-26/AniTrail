import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/api_http_client.dart';

class UserProfile {
  final String userId;
  final String? username;
  final String? avatarUrl;

  const UserProfile({required this.userId, this.username, this.avatarUrl});

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    userId: json['user_id'] as String,
    username: json['username'] as String?,
    avatarUrl: json['avatar_url'] as String?,
  );
}

class ProfileService {
  ProfileService({http.Client? client})
    : _client = client ?? ApiHttpClient.shared;

  final http.Client _client;

  String get _baseUrl {
    final value = dotenv.env['API_BASE_URL'];
    if (value == null || value.isEmpty) {
      throw StateError('API_BASE_URL が .env に設定されていません');
    }
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  Map<String, String> get _authHeaders {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) throw StateError('プロフィールの取得にはログインが必要です');
    return {'Authorization': 'Bearer $token'};
  }

  Future<UserProfile> fetchMyProfile() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/profiles/me'),
      headers: _authHeaders,
    );
    if (response.statusCode != 200) {
      throw Exception('プロフィールの取得に失敗しました (${response.statusCode})');
    }
    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) throw StateError('プロフィールが見つかりません');
    return UserProfile.fromJson(data);
  }

  Future<UserProfile> updateUsername(String username) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/profiles/me'),
      headers: {..._authHeaders, 'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}),
    );
    if (response.statusCode != 200) {
      throw Exception('ユーザー名の保存に失敗しました (${response.statusCode})');
    }
    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) throw StateError('保存したプロフィールを取得できませんでした');
    return UserProfile.fromJson(data);
  }
}
