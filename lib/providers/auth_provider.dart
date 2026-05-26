import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../services/auth_Service.dart';

enum AuthStatus { idle, loading, success, error }

// OTP の用途を区別する
enum OtpPurpose { register, forgotPassword }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;

  // OTP 検証時に使うメールアドレスと用途を保持
  String? _pendingEmail;
  OtpPurpose _otpPurpose = OtpPurpose.register;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  String? get pendingEmail => _pendingEmail;
  OtpPurpose get otpPurpose => _otpPurpose;

  final AuthService authService = AuthService();

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void _setSuccess() {
    _status = AuthStatus.success;
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _status = AuthStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  //ログイン
  Future<void> login({required String email, required String password}) async {
    _setLoading();
    try {
      await authService.login(email: email.trim(), password: password);
      _setSuccess();
    } catch (e) {
      debugPrint('Login error: $e');
      _setError(e.toString());
    }
  }

  //新規登録
  Future<void> register({
    required String email,
    required String password,
    String? username,
  }) async {
    _setLoading();
    try {
      await authService.signUp(
        email: email.trim(),
        password: password,
        data: username != null && username.isNotEmpty
            ? {'username': username}
            : null,
      );
      debugPrint('Register success - email: $email');
      _pendingEmail = email.trim();
      _otpPurpose = OtpPurpose.register;
      _setSuccess();
    } on AuthException catch (e) {
      debugPrint('Register AuthException: ${e.message}');
      _setError(e.message);
    } catch (e) {
      debugPrint('Register error: $e');
      _setError(e.toString());
    }
  }

  //パスワード再設定
  Future<void> updatePassword({required String newPassword}) async {
    _setLoading();
    try {
      await authService.updatePassword(newPassword: newPassword);
      _setSuccess();
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('パスワード変更に失敗しました。もう一度お試しください。');
    }
  }

  Future<void> sendPasswordResetOtp({required String email}) async {
    _setLoading();

    try {
      _otpPurpose = OtpPurpose.forgotPassword;

      await authService.sendPasswordResetOtp(email: email);

      _setSuccess();
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> verifyOtp({
    required String email,
    required String otp,
    required OtpPurpose purpose,
  }) async {
    _setLoading();

    try {
      final type = purpose == OtpPurpose.register
          ? OtpType.signup
          : OtpType.recovery;

      await authService.verifyOTP(
        email: email.trim(),
        token: otp.trim(),
        type: type,
      );

      _setSuccess();
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }
  }

  //googleでログイン
  Future<bool> loginWithGoogle() async {
    _setLoading();

    try {
      const webClientId =
          '967359570383-5kp1oumcu0lhto2326ldjve3o0fhit7p.apps.googleusercontent.com';

      const androidClientId =
          '967359570383-aenbq6srjhkc2l16lf5cmrram0cbtdoe.apps.googleusercontent.com';

      final googleSignIn = GoogleSignIn.instance;

      await googleSignIn.initialize(
        serverClientId: webClientId,
        clientId: androidClientId,
      );

      final googleUser = await googleSignIn.authenticate();

      final authorization = await googleUser.authorizationClient
          .authorizeScopes(['email', 'profile']);

      final accessToken = authorization.accessToken;
      final idToken = googleUser.authentication.idToken;

      if (idToken == null) {
        _setError('No ID Token found');
        return false;
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      _setSuccess();

      return true;
    } catch (e) {
      _setError(e.toString());

      return false;
    }
  }
}
