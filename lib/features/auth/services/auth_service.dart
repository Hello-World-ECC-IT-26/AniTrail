import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  /// メールアドレス＋パスワードでログイン
  Future<void> login({required String email, required String password}) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
    await ensureProfile();
  }

  /// 新規登録（メール認証OTPが送信される）
  Future<void> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    await supabase.auth.signUp(email: email, password: password, data: data);
  }

  /// OTP検証（新規登録 or パスワードリセット）
  Future<void> verifyOTP({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    await supabase.auth.verifyOTP(email: email, token: token, type: type);
    if (type == OtpType.signup) await ensureProfile();
  }

  /// 新規登録時のメール認証コードを再送する。
  ///
  /// `OtpType.signup` で発行したコードは、同じ用途で検証しなければ
  /// Supabase に無効なトークンとして拒否される。
  Future<void> resendSignupOtp({required String email}) async {
    await supabase.auth.resend(email: email, type: OtpType.signup);
  }

  /// stamp_cards など、profiles.user_id を参照する機能の前提行を保証する。
  Future<void> ensureProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final token = supabase.auth.currentSession?.accessToken;
    if (token == null) return;
    final baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw StateError('API_BASE_URL が .env に設定されていません');
    }
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final username = _firstMetadataString(metadata, const [
      'username',
      'full_name',
      'name',
      'preferred_username',
    ]);
    final avatarUrl = _firstMetadataString(metadata, const [
      'avatar_url',
      'picture',
      'avatar',
    ]);
    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final response = await http.post(
      Uri.parse('$normalizedBaseUrl/profiles'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        if (username != null) 'username': username,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      }),
    );
    if (response.statusCode != 200) {
      var detail = '';
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        detail = body is Map ? (body['error']?.toString() ?? '') : '';
      } catch (_) {
        detail = utf8.decode(response.bodyBytes);
      }
      throw Exception(
        'プロフィールの初期化に失敗しました (${response.statusCode})'
        '${detail.isEmpty ? '' : ': $detail'}',
      );
    }
  }

  String? _firstMetadataString(
    Map<String, dynamic> metadata,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = metadata[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  /// メール認証後の認証済みセッションで、プロフィール写真をR2へ保存する。
  Future<void> uploadAvatar(XFile image) async {
    final token = supabase.auth.currentSession?.accessToken;
    if (token == null) {
      throw StateError('プロフィール写真の保存には認証済みセッションが必要です');
    }
    final baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw StateError('API_BASE_URL が .env に設定されていません');
    }

    final bytes = await image.readAsBytes();
    final contentType =
        image.mimeType?.toLowerCase() ??
        lookupMimeType(image.name, headerBytes: bytes)?.toLowerCase();
    const allowedTypes = {'image/jpeg', 'image/png', 'image/webp', 'image/gif'};
    if (contentType == null || !allowedTypes.contains(contentType)) {
      throw StateError('対応していない画像形式です');
    }

    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$normalizedBaseUrl/profiles/avatar'),
    )..headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: image.name,
        contentType: MediaType.parse(contentType),
      ),
    );
    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode != 200) {
      var detail = '';
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        detail = body is Map ? (body['error']?.toString() ?? '') : '';
      } catch (_) {
        detail = utf8.decode(response.bodyBytes);
      }
      throw Exception(
        'プロフィール写真の保存に失敗しました (${response.statusCode})'
        '${detail.isEmpty ? '' : ': $detail'}',
      );
    }
  }

  /// パスワードリセット用OTPをメール送信
  Future<void> sendPasswordResetOtp({required String email}) async {
    await supabase.auth.resetPasswordForEmail(email);
  }

  /// OTP検証後、新しいパスワードに更新
  Future<void> updatePassword({required String newPassword}) async {
    await supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// サインアウト
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
