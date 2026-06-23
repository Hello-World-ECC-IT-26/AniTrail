import 'package:flutter/material.dart';

import 'app_styles.dart';

class AppTextStyles {
  static const TextStyle label = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
  );

  static const TextStyle hint = TextStyle(
    fontSize: 13,
    color: AppColors.textHint,
  );

  static const TextStyle input = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle error = TextStyle(
    fontSize: 11,
    color: AppColors.error,
  );

  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static const TextStyle buttonOutline = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const TextStyle buttonGoogle = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// 画面内の見出し（18 / bold）。
  static const TextStyle heading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// セクション小見出し（16 / bold）。
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// 本文（14 / regular）。
  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  /// 補足本文（14 / secondary）。
  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  /// キャプション（12 / muted）。
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textMuted,
  );

  static const TextStyle successMessage = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
}
