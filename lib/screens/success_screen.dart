import 'package:flutter/material.dart';
import '../constants/app_constans.dart';
import '../styles/app_styles.dart';
import '../styles/app_text.dart';
import '../widgets/app_buttons.dart';

enum SuccessType { register, login, password }

class SuccessScreen extends StatelessWidget {
  final SuccessType type;

  const SuccessScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final message = switch (type) {
      SuccessType.register => '新規登録完了しました！',
      SuccessType.login => 'ログイン完了しました！',
      SuccessType.password => 'パスワードの変更完了しました！',
    };

    final buttonLabel = switch (type) {
      SuccessType.register => 'アプリへすすむ',
      SuccessType.login => 'アプリへすすむ',
      SuccessType.password => 'ログインへ戻る',
    };

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // ── 上部の青いセクション ────────────────────────────
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              color: AppColors.primary,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ── キラキラ星の装飾 ──────────────────────
                  const Positioned(
                    top: 60,
                    left: 40,
                    child: _StarIcon(size: 18),
                  ),
                  const Positioned(
                    top: 80,
                    left: 80,
                    child: _StarIcon(size: 12),
                  ),
                  const Positioned(
                    top: 40,
                    right: 60,
                    child: _StarIcon(size: 14),
                  ),
                  const Positioned(
                    top: 100,
                    right: 40,
                    child: _StarIcon(size: 20),
                  ),
                  const Positioned(
                    bottom: 60,
                    left: 50,
                    child: _StarIcon(size: 16),
                  ),
                  const Positioned(
                    bottom: 80,
                    right: 55,
                    child: _StarIcon(size: 12),
                  ),

                  // ── チェックマーク付きの白い円 ──────────────
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: AppColors.primary,
                      size: 52,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 下部の白いセクション ────────────────────────
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── 完了メッセージ ──────────────────────
                  Text(message, style: AppTextStyles.successMessage),
                  const SizedBox(height: 40),

                  // ── アクションボタン ────────────────────
                  PrimaryButton(
                    label: buttonLabel,
                    onPressed: () {
                      if (type == SuccessType.password) {
                        // パスワード変更後はログイン画面へ戻る
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppConstants.routeLogin,
                          (route) => false,
                        );
                      } else {
                        // 登録・ログイン後はホーム画面へ進む
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppConstants.routeHome,
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── キラキラ星ウィジェット ─────────────────────────────────────
class _StarIcon extends StatelessWidget {
  final double size;

  const _StarIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.auto_awesome, color: Colors.white, size: size);
  }
}
