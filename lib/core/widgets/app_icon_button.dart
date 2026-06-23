import 'package:flutter/material.dart';

import '../styles/app_styles.dart';

/// 画像の上などに重ねる円形アイコンボタン（半透明の白背景）。
/// 聖地詳細のブックマークボタンなどで使う。
class AppCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color iconColor;
  final double size;
  final double iconSize;

  const AppCircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.primary,
    this.size = 34,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}
