import 'package:flutter/material.dart';

import 'app_dimens.dart';
import 'app_styles.dart';
import 'app_text.dart';

class AppInputBorder {
  static const UnderlineInputBorder enabled = UnderlineInputBorder(
    borderSide: BorderSide(color: AppColors.borderDefault),
  );

  static const UnderlineInputBorder focused = UnderlineInputBorder(
    borderSide: BorderSide(color: AppColors.borderFocused, width: 2),
  );

  static const UnderlineInputBorder error = UnderlineInputBorder(
    borderSide: BorderSide(color: AppColors.borderError),
  );

  static const UnderlineInputBorder focusedError = UnderlineInputBorder(
    borderSide: BorderSide(color: AppColors.borderError, width: 2),
  );
}

/// 検索バーやしおり入力など、塗りつぶし型の入力欄で共通利用する装飾。
class AppInputDecorations {
  /// グレー塗り・角丸・枠線なしの入力装飾。
  static InputDecoration filled({
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    Color fillColor = AppColors.surfaceVariant,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.hint,
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: AppColors.iconMuted, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: AppRadius.brMd,
        borderSide: BorderSide.none,
      ),
    );
  }
}
