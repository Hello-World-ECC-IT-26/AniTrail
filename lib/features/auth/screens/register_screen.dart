import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_dimens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_app_bar.dart';
import '../widgets/temp.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'ユーザー名を入力してください';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'メールアドレスを入力してください';
    final emailRegex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'メールアドレス形式で入力してください';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'パスワードを入力してください';
    if (value.length < AppConstants.passwordMinLength) return '8文字以上で入力してください';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'パスワードを再入力してください';
    if (value != _passwordController.text) return '※上記と同じパスワードを入力してください';
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();

    await auth.register(
      email: _emailController.text,
      password: _passwordController.text,
      username: _usernameController.text,
    );

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
          content: Text(auth.errorMessage ?? '登録に失敗しました'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AuthAppBar(title: 'アカウント新規登録'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.lg),

                        const ProfileAvatar(),

                        const SizedBox(height: AppSpacing.xxxl),

                        // ── Username Field ─────────────────────────
                        CustomTextField(
                          label: 'ユーザー名',
                          hintText: 'スタンプ太郎',
                          prefixIcon: Icons.person_outline,
                          controller: _usernameController,
                          validator: _validateUsername,
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // ── Email Field ────────────────────────────
                        CustomTextField(
                          label: 'メールアドレス',
                          hintText: 'helloworld@gmail.com',
                          prefixIcon: Icons.email_outlined,
                          controller: _emailController,
                          validator: _validateEmail,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // ── Password Field ─────────────────────────
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
                          hintText: '●●●●●●●●',
                          prefixIcon: Icons.lock_outline,
                          controller: _confirmController,
                          isPassword: true,
                          validator: _validateConfirm,
                        ),

                        const Spacer(),
                        const SizedBox(height: AppSpacing.xl),

                        // ── Register Button ────────────────────────
                        PrimaryButton(
                          label: '新規登録',
                          onPressed: _handleRegister,
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
