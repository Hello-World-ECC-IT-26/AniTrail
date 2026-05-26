import 'package:AniTrail/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:AniTrail/widgets/auth_logo.dart';
import '../constants/app_constans.dart';
import '../styles/app_styles.dart';
import '../widgets/app_buttons.dart';
import '../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'メールアドレスを入力してください';
    final emailRegex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'メールアドレス形式で入力してください';
    return null;
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    await auth.sendPasswordResetOtp(email: _emailController.text);

    if (!mounted) return;

    if (auth.status == AuthStatus.success) {
      // OTP 画面へ（forgotPassword 用途）
      Navigator.pushNamed(
        context,
        AppConstants.routeOtp,
        arguments: _emailController.text.trim(),
      );
    } else if (auth.status == AuthStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'メール送信に失敗しました'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'アカウント新規登録',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 32),

                // ── Logo ───────────────────────────────────
                const AuthLogo(),

                const SizedBox(height: 32),

                // ── Email Field ────────────────────────────
                CustomTextField(
                  label: 'メールアドレス',
                  hintText: 'helloworld@gmail.com',
                  prefixIcon: Icons.email_outlined,
                  controller: _emailController,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 48),

                // ── Next Button ────────────────────────────
                PrimaryButton(label: '送信', onPressed: _handleNext),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
