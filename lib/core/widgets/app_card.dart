import 'package:flutter/material.dart';

import '../styles/app_dimens.dart';
import '../styles/app_shadows.dart';
import '../styles/app_styles.dart';

/// 白背景・角丸・やわらかい影を持つ共通カード。
///
/// `Container(decoration: BoxDecoration(...))` を各画面で直書きせずこれを使う。
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double radius;

  /// 画像などを角丸でクリップしたい場合に true。
  final bool clip;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.radius = AppRadius.lg,
    this.clip = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }
    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: content,
        ),
      );
    }
    return Container(
      margin: margin,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: borderRadius,
        boxShadow: AppShadows.card,
      ),
      child: content,
    );
  }
}
