import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  /// メールアドレス＋パスワードでログイン
  Future<void> login({required String email, required String password}) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
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
