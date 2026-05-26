import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

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

  static const TextStyle successMessage = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
}
