import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

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
