import 'package:flutter/material.dart';

import '../styles/app_dimens.dart';
import '../styles/app_styles.dart';

/// 画面下部に固定する横幅いっぱいのアクションバー。
/// 「しおりに追加」など主要操作で使う。
class AppBottomActionBar extends StatelessWidget {
  /// 先頭アイコン（null ならテキストのみ）。
  final IconData? icon;
  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;

  const AppBottomActionBar({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      minimumSize: const Size(double.infinity, 0),
      foregroundColor: AppColors.white,
    );
    final text = Text(
      label,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
    return Container(
      color: backgroundColor,
      child: icon == null
          ? TextButton(onPressed: onPressed, style: style, child: text)
          : TextButton.icon(
              onPressed: onPressed,
              style: style,
              icon: Icon(icon, color: AppColors.white),
              label: text,
            ),
    );
  }
}
