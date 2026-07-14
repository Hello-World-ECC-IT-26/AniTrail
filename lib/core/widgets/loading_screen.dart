import 'package:flutter/material.dart';

import '../styles/app_dimens.dart';
import '../styles/app_styles.dart';
import '../styles/app_text.dart';

/// 画面または画面内の主要表示領域を覆う共通ローディング表示。
class AppLoadingScreen extends StatelessWidget {
  final String message;
  final double imageSize;
  final Color backgroundColor;
  final Color? textColor;

  const AppLoadingScreen({
    super.key,
    this.message = '読み込んでいます・・・',
    this.imageSize = 200,
    this.backgroundColor = AppColors.background,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/loading.gif',
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.contain,
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle.copyWith(color: textColor),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
