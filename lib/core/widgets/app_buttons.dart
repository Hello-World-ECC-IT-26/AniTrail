import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../styles/app_dimens.dart';
import '../styles/app_styles.dart';
import '../styles/app_text.dart';

/// ボタンの種類。
enum AppButtonVariant {
  /// 塗りつぶし（主アクション）。
  primary,

  /// 枠線のみ（副アクション）。
  secondary,

  /// 背景なしテキスト。
  text,
}

/// ボタンのサイズ。
enum AppButtonSize {
  /// 標準（高さ48）。
  regular,

  /// 小さめ（リスト内・コンパクトな場面）。
  compact,
}

/// アプリ共通ボタン。色・角丸・余白・文字サイズを統一する。
///
/// 画面ごとに `ElevatedButton` / `TextButton` を直書きせず、これを使う。
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final double? height;

  /// 横幅いっぱいに広げるか。false なら内容に合わせた幅。
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.height,
  });

  bool get _compact => size == AppButtonSize.compact;

  /// compact のときは余分なタップ余白を削り、狭い行でも収まるようにする。
  MaterialTapTargetSize? get _tapTargetSize =>
      _compact ? MaterialTapTargetSize.shrinkWrap : null;

  Size? get _minimumSize => _compact ? Size.zero : null;

  EdgeInsets get _padding => _compact
      ? const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        )
      : const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        );

  TextStyle get _textStyle {
    final base = _compact
        ? AppTextStyles.button.copyWith(fontSize: 13)
        : AppTextStyles.button;
    switch (variant) {
      case AppButtonVariant.primary:
        return base; // 白文字
      case AppButtonVariant.secondary:
      case AppButtonVariant.text:
        return base.copyWith(color: AppColors.primary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: AppRadius.brSm);
    final disabled = isLoading ? null : onPressed;

    final Widget child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: variant == AppButtonVariant.primary
                  ? AppColors.white
                  : AppColors.primary,
              strokeWidth: 2.5,
            ),
          )
        : _label();

    final Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: disabled,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.primaryLight,
            padding: _padding,
            shape: shape,
            elevation: 0,
            tapTargetSize: _tapTargetSize,
            minimumSize: _minimumSize,
          ),
          child: child,
        );
      case AppButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: disabled,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            padding: _padding,
            shape: shape,
            tapTargetSize: _tapTargetSize,
            minimumSize: _minimumSize,
          ),
          child: child,
        );
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: disabled,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: _padding,
            shape: shape,
            tapTargetSize: _tapTargetSize,
            minimumSize: _minimumSize,
          ),
          child: child,
        );
    }

    if (size == AppButtonSize.regular && !_compact) {
      return SizedBox(
        width: fullWidth ? double.infinity : null,
        height: height ?? AppSizes.buttonHeight,
        child: button,
      );
    }
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _label() {
    if (icon == null) return Text(label, style: _textStyle);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: _textStyle),
      ],
    );
  }
}

/// 横幅いっぱいの主ボタン（既存の呼び出し互換）。
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) =>
      AppButton(label: label, onPressed: onPressed, isLoading: isLoading);
}

/// 横幅いっぱいの副ボタン（既存の呼び出し互換）。
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => AppButton(
    label: label,
    onPressed: onPressed,
    variant: AppButtonVariant.secondary,
  );
}

class AppLinkText extends StatelessWidget {
  final String prefixText;
  final String linkText;
  final VoidCallback onTap;

  const AppLinkText({
    super.key,
    required this.prefixText,
    required this.linkText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.hint,
        children: [
          TextSpan(text: prefixText),
          TextSpan(
            text: linkText,
            style: AppTextStyles.hint.copyWith(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()..onTap = onTap,
          ),
        ],
      ),
    );
  }
}

class GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const GoogleButton({super.key, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.grey),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brSm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/google.png',
                width: 18,
                height: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Google でログイン', style: AppTextStyles.buttonGoogle),
          ],
        ),
      ),
    );
  }
}
