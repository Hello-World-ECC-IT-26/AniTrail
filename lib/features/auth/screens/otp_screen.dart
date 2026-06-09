import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/widgets/app_buttons.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final int length = AppConstants.otpLength;

  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  Timer? _timer;
  int _seconds = 60;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(length, (_) => TextEditingController());
    _focusNodes = List.generate(length, (_) => FocusNode());

    _focusNodes.first.requestFocus();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();

    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // OTP再送信タイマー
  void _startTimer() {
    _seconds = 60;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 0) {
        timer.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  bool get _canResend => _seconds == 0;

  // OTP値の取得
  String get _otp => _controllers.map((e) => e.text).join();
  bool get _isComplete => _otp.length == length;

  // 入力処理
  void _onChanged(String value, int index) {
    // OTP貼り付け処理
    if (value.length > 1) {
      _handlePaste(value);
      return;
    }

    if (value.isNotEmpty && index < length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});

    if (_isComplete) {
      _handleNext();
    }
  }

  void _handlePaste(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '').split('');

    for (int i = 0; i < length; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }

    setState(() {});

    if (_isComplete) {
      _handleNext();
    }
  }

  // OTP検証
  Future<void> _handleNext() async {
    if (!_isComplete) return;

    final auth = context.read<AuthProvider>();

    await auth.verifyOtp(
      email: widget.email,
      otp: _otp,
      purpose: auth.otpPurpose,
    );

    if (!mounted) return;

    if (auth.status == AuthStatus.success) {
      if (auth.otpPurpose == OtpPurpose.register) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppConstants.routeSuccessRegister,
          (_) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppConstants.routePasswordChange,
          (_) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? '認証コードが正しくありません'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // OTP再送信
  Future<void> _handleResend() async {
    if (!_canResend) return;

    final auth = context.read<AuthProvider>();

    await auth.sendPasswordResetOtp(email: widget.email);

    _startTimer();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('OTPを再送信しました')));
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'メールアドレス認証',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),

            Text('認証コード', style: AppTextStyles.title),

            const SizedBox(height: 10),

            Text(
              'コードは ${widget.email} に送信されました',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),

            const SizedBox(height: 30),

            // ───── OTP入力ボックス ─────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(length, (i) {
                return SizedBox(
                  width: 50,
                  height: 60,
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    onChanged: (v) => _onChanged(v, i),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            // ───── OTP再送信 ─────
            GestureDetector(
              onTap: _handleResend,
              child: Text(
                _canResend ? 'コードを再送信' : 'あと $_seconds 秒で再送信できます',
                style: TextStyle(
                  color: _canResend ? AppColors.primary : Colors.grey,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

            const SizedBox(height: 40),

            PrimaryButton(label: '認証する', onPressed: _handleNext),
          ],
        ),
      ),
    );
  }
}
