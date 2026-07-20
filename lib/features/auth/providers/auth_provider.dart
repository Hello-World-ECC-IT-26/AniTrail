import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../../map/services/spot_api.dart';

enum AuthStatus { idle, loading, success, error }

// OTP の用途を区別する
enum OtpPurpose { register, forgotPassword }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;

  // OTP 検証時に使うメールアドレスと用途を保持
  String? _pendingEmail;
  OtpPurpose _otpPurpose = OtpPurpose.register;
  XFile? _pendingAvatar;

  StreamSubscription<AuthState>? _authSubscription;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  String? get pendingEmail => _pendingEmail;
  OtpPurpose get otpPurpose => _otpPurpose;
  bool get isAuthenticated =>
      Supabase.instance.client.auth.currentSession != null;

  final AuthService authService = AuthService();

  AuthProvider() {
    if (isAuthenticated) {
      unawaited(
        authService.ensureProfile().catchError((error) {
          debugPrint('Profile initialization failed: $error');
        }),
      );
    }
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      _,
    ) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  bool _startRequest() {
    if (isLoading) return false;

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    return true;
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

  //ログアウト
  Future<void> logout() async {
    if (!_startRequest()) return;
    try {
      await SpotApi().clearUserCaches();
      await authService.signOut();
      _setSuccess();
    } catch (e) {
      _setError('ログアウトに失敗しました');
    }
  }

  //ログイン
  Future<void> login({required String email, required String password}) async {
    if (!_startRequest()) return;
    try {
      await authService.login(email: email.trim(), password: password);
      _setSuccess();
    } catch (e) {
      debugPrint('Login error: $e');
      _setError('メールアドレスまたはパスワードが正しくありません');
    }
  }

  //新規登録
  Future<void> register({
    required String email,
    required String password,
    String? username,
    XFile? avatar,
  }) async {
    if (!_startRequest()) return;
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
      _pendingAvatar = avatar;
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
    if (!_startRequest()) return;
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
    if (!_startRequest()) return;

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

  Future<void> resendOtp({
    required String email,
    required OtpPurpose purpose,
  }) async {
    if (!_startRequest()) return;

    try {
      if (purpose == OtpPurpose.register) {
        await authService.resendSignupOtp(email: email.trim());
      } else {
        await authService.sendPasswordResetOtp(email: email.trim());
      }
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
    if (!_startRequest()) return;

    try {
      final type = purpose == OtpPurpose.register
          ? OtpType.signup
          : OtpType.recovery;

      await authService.verifyOTP(
        email: email.trim(),
        token: otp.trim(),
        type: type,
      );
      if (purpose == OtpPurpose.register && _pendingAvatar != null) {
        await authService.uploadAvatar(_pendingAvatar!);
        _pendingAvatar = null;
      }

      _setSuccess();
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }
  }

  //googleでログイン
  Future<bool> loginWithGoogle() async {
    if (!_startRequest()) return false;

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
      await authService.ensureProfile();

      _setSuccess();

      return true;
    } catch (e) {
      _setError(e.toString());

      return false;
    }
  }
}
