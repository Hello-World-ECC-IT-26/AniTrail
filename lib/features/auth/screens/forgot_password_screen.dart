import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_dimens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_app_bar.dart';
import '../widgets/auth_logo.dart';

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
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AuthAppBar(title: 'パスワード変更', toolbarHeight: 100),
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

                // ── Email Field ────────────────────────────
                CustomTextField(
                  label: 'メールアドレス',
                  hintText: 'hello@example.com',
                  prefixIcon: Icons.email_outlined,
                  controller: _emailController,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                ),

                // ── Push button to bottom ──────────────────
                const Spacer(),

                // ── Next Button ────────────────────────────
                PrimaryButton(
                  label: '送信',
                  onPressed: isLoading ? null : _handleNext,
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
