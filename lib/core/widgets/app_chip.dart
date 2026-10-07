import 'package:flutter/material.dart';

import '../styles/app_dimens.dart';
import '../styles/app_styles.dart';

/// フィルタ用のピル型チップ。選択状態で主色に塗る。
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
            : const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
        decoration: BoxDecoration(
          color: selected
              ? (compact ? AppColors.tourPrimary : AppColors.primary)
              : AppColors.grey,
          borderRadius: BorderRadius.circular(compact ? 4 : AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.textSecondary,
            fontSize: compact ? 12 : 13,
            letterSpacing: compact ? 0.25 : null,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
