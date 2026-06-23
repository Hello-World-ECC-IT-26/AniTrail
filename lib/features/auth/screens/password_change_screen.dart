import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_app_bar.dart';
import '../widgets/auth_logo.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_dimens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/custom_text_field.dart';

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
    if (value == null || value.isEmpty) return 'パスワードを再入力してください';
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
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AuthAppBar(title: 'パスワード変更'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ── Logo ───────────────────────────────────
                const AuthLogo(),

                const SizedBox(height: AppSpacing.xxxl),

                // ── New Password Field ─────────────────────
                CustomTextField(
                  label: 'パスワード',
                  hintText: 'helloworld315',
                  prefixIcon: Icons.lock_outline,
                  controller: _passwordController,
                  isPassword: true,
                  validator: _validatePassword,
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Confirm Password Field ─────────────────
                CustomTextField(
                  label: 'パスワード再入力',
                  hintText: '●●●●●●●●●●',
                  prefixIcon: Icons.lock_outline,
                  controller: _confirmController,
                  isPassword: true,
                  validator: _validateConfirm,
                ),

                // ── Push button to bottom ──────────────────
                const Spacer(),

                // ── Submit Button ──────────────────────────
                PrimaryButton(
                  label: '登録',
                  onPressed: isLoading ? null : _handleSubmit,
                  isLoading: isLoading,
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
