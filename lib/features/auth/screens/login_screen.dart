import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_logo.dart';
import 'success_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'メールアドレスを入力してください';
    final emailRegex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'メールアドレス形式で入力してください';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'パスワードを入力してください';
    if (value.length < AppConstants.passwordMinLength) {
      return '※半角英数字8文字以上で入力してください';
    }
    return null;
  }

  // ── Login ─────────────────────────────────────────────
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    await auth.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (auth.status == AuthStatus.success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppConstants.routeSuccessLogin,
        (route) => false,
      );
    } else if (auth.status == AuthStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'ログインに失敗しました'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ── Logo ───────────────────────────────────
                const SizedBox(height: 100),
                const AuthLogo(),
                const SizedBox(height: 32),

                // ── Email Field ────────────────────────────
                CustomTextField(
                  label: 'メールアドレス',
                  hintText: 'hello@example.com',
                  prefixIcon: Icons.email_outlined,
                  controller: _emailController,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 16),

                // ── Password Field ─────────────────────────
                CustomTextField(
                  label: 'パスワード',
                  hintText: '●●●●●●●●',
                  prefixIcon: Icons.lock_outline,
                  controller: _passwordController,
                  isPassword: true,
                  validator: _validatePassword,
                ),

                // ── Push button to bottom ──────────────────
                const Spacer(),

                PrimaryButton(
                  label: 'ログイン',
                  onPressed: isLoading ? null : _handleLogin,
                  isLoading: isLoading,
                ),

                const SizedBox(height: 20),

                // ── Forgot Password ────────────────────────
                AppLinkText(
                  prefixText: 'パスワードをお忘れの方は',
                  linkText: 'こちら',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppConstants.routeForgotPassword,
                    );
                  },
                ),

                const SizedBox(height: 20),

                // ── Divider ────────────────────────────────
                const Divider(
                  thickness: 1,
                  color: Color.fromARGB(255, 102, 102, 102),
                ),
                const SizedBox(height: 20),

                // ── Register Button ────────────────────────
                SecondaryButton(
                  label: '新規登録',
                  onPressed: isLoading
                      ? null
                      : () => Navigator.pushNamed(
                          context,
                          AppConstants.routeRegister,
                        ),
                ),

                const SizedBox(height: 12),

                // ── Google Button ──────────────────────────
                GoogleButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final success = await context
                              .read<AuthProvider>()
                              .loginWithGoogle();

                          if (!context.mounted) return;

                          if (success) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SuccessScreen(
                                  type: SuccessType.login,
                                ),
                              ),
                            );
                          } else {
                            final err = context
                                .read<AuthProvider>()
                                .errorMessage;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err ?? 'Googleログインに失敗しました'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
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
