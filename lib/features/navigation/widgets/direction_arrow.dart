import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/navigation_direction.dart';

class DirectionArrow extends StatelessWidget {
  final double? routeBearingDegrees;
  final double? destinationBearingDegrees;
  final double? deviceHeadingDegrees;
  final double size;

  const DirectionArrow({
    super.key,
    required this.routeBearingDegrees,
    required this.destinationBearingDegrees,
    required this.deviceHeadingDegrees,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final heading = deviceHeadingDegrees;
    final relativeRouteDirection =
        routeBearingDegrees == null || heading == null
        ? null
        : relativeDirectionDegrees(
            bearingDegrees: routeBearingDegrees!,
            deviceHeadingDegrees: heading,
          );
    final relativeDestinationDirection =
        destinationBearingDegrees == null || heading == null
        ? null
        : relativeDirectionDegrees(
            bearingDegrees: destinationBearingDegrees!,
            deviceHeadingDegrees: heading,
          );
    final alignment = navigationDirectionAlignment(
      routeBearingDegrees: routeBearingDegrees,
      deviceHeadingDegrees: heading,
    );
    final pinWidth = math.min(28.0, size * 0.075);
    final pinHeight = pinWidth * 41 / 28;
    final radius = size * 0.44;
    final pinAngle = relativeDestinationDirection == null
        ? null
        : relativeDestinationDirection * math.pi / 180;
    final pinLeft = relativeDestinationDirection == null
        ? null
        : size / 2 + math.sin(pinAngle!) * radius - pinWidth / 2;
    final pinTop = relativeDestinationDirection == null
        ? null
        : size / 2 - math.cos(pinAngle!) * radius - pinHeight;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DirectionIndicatorPainter(
                alignment: alignment,
                relativeRouteDirection: relativeRouteDirection,
              ),
            ),
          ),
          if (pinLeft != null && pinTop != null)
            Positioned(
              left: pinLeft,
              top: pinTop,
              child: SvgPicture.asset(
                'assets/images/pin.svg',
                width: pinWidth,
                height: pinHeight,
              ),
            ),
        ],
      ),
    );
  }
}

class _DirectionIndicatorPainter extends CustomPainter {
  const _DirectionIndicatorPainter({
    required this.alignment,
    required this.relativeRouteDirection,
  });

  final NavigationDirectionAlignment alignment;
  final double? relativeRouteDirection;

  static const _correctColor = Color(0xFF1878F3);
  static const _incorrectColor = Color(0xFFFFD84D);
  static const _unavailableColor = Color(0xFF9E9E9E);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.44;
    final ringColor = switch (alignment) {
      NavigationDirectionAlignment.aligned => _correctColor,
      NavigationDirectionAlignment.misaligned => _incorrectColor,
      NavigationDirectionAlignment.unavailable => _unavailableColor,
    };

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.min(size.width, size.height) * 0.026
        ..strokeCap = StrokeCap.round,
    );

    final routeDirection = relativeRouteDirection;
    if (routeDirection != null) {
      _drawRouteArrow(canvas, center, size, routeDirection);
    }
  }

  void _drawRouteArrow(
    Canvas canvas,
    Offset center,
    Size size,
    double directionDegrees,
  ) {
    final shortestSide = math.min(size.width, size.height);
    final path = Path()
      ..moveTo(0, -shortestSide * 0.42)
      ..lineTo(shortestSide * 0.25, shortestSide * 0.28)
      ..lineTo(0, shortestSide * 0.12)
      ..lineTo(-shortestSide * 0.25, shortestSide * 0.28)
      ..close();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(directionDegrees * math.pi / 180);
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DirectionIndicatorPainter oldDelegate) {
    return alignment != oldDelegate.alignment ||
        relativeRouteDirection != oldDelegate.relativeRouteDirection;
  }
}
