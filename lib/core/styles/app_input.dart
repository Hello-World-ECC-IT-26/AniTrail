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
  static InputDecoration filled({
    String? hintText,
    Widget? prefix,
    Widget? suffix,
    IconData? prefixIcon,
    Widget? suffixIcon,
    Color fillColor = AppColors.surfaceVariant,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.hint,

      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.iconMuted, size: 20)
          : prefix,

      suffixIcon: suffixIcon ?? suffix,

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
