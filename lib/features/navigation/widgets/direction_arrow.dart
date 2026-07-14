import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';

class DirectionArrow extends StatelessWidget {
  final double? deviceHeadingDegrees;
  final double size;

  const DirectionArrow({
    super.key,
    required this.deviceHeadingDegrees,
    required this.size,
  });

  static const _needleNorthOffsetDegrees = -45.0;

  @override
  Widget build(BuildContext context) {
    final heading = deviceHeadingDegrees;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/compass_base.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            cacheWidth: (size * 2).round(),
            filterQuality: FilterQuality.medium,
          ),
          if (heading == null)
            _buildNoHeadingState()
          else
            Transform.rotate(
              angle:
                  (-heading + _needleNorthOffsetDegrees) * math.pi / 180,
              child: Image.asset(
                'assets/images/compass_needle.png',
                width: size * 0.46,
                height: size * 0.46,
                fit: BoxFit.contain,
                cacheWidth: (size * 0.92).round(),
                filterQuality: FilterQuality.medium,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoHeadingState() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          '方位取得中',
          style: AppTextStyles.subtitle.copyWith(color: AppColors.white),
        ),
      ),
    );
  }
}
