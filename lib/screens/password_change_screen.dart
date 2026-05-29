import 'package:AniTrail/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:AniTrail/widgets/auth_logo.dart';
import '../constants/app_constans.dart';
import '../styles/app_styles.dart';
import '../widgets/app_buttons.dart';
import '../widgets/custom_text_field.dart';

class PasswordChangeScreen extends StatefulWidget {
  const PasswordChangeScreen({super.key});

  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'パスワードを入力してください';
    if (value.length < AppConstants.passwordMinLength) {
      return '※半角英数字8文字以上で入力してください';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _passwordController.text) return '※上記と同じパスワードを入力してください';
    return null;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    await auth.updatePassword(newPassword: _passwordController.text);

    if (!mounted) return;

    if (auth.status == AuthStatus.success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppConstants.routeSuccessPassword,
        (route) => false,
      );
    } else if (auth.status == AuthStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'パスワード変更に失敗しました'),
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
        toolbarHeight: 80,
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'パスワード変更',
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
                // ── Logo ───────────────────────────────────
                const AuthLogo(),

                const SizedBox(height: 32),

                // ── New Password Field ─────────────────────
                CustomTextField(
                  label: 'パスワード',
                  hintText: 'helloworld315',
                  prefixIcon: Icons.lock_outline,
                  controller: _passwordController,
                  isPassword: true,
                  validator: _validatePassword,
                ),

                const SizedBox(height: 16),

                // ── Confirm Password Field ─────────────────
                CustomTextField(
                  label: 'パスワード再入力',
                  hintText: '●●●●●●●●●●',
                  prefixIcon: Icons.lock_outline,
                  controller: _confirmController,
                  isPassword: true,
                  validator: _validateConfirm,
                ),

                const SizedBox(height: 48),

                // ── Submit Button ──────────────────────────
                SizedBox(height: 400),
                PrimaryButton(label: '登録', onPressed: _handleSubmit),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
