import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/styles/app_styles.dart';
import '../services/stamp_image_store.dart';

class StampBadge extends StatefulWidget {
  final String spotId;
  final String label;
  final double? size;

  const StampBadge({
    super.key,
    required this.spotId,
    required this.label,
    this.size,
  });

  @override
  State<StampBadge> createState() => _StampBadgeState();
}

class _StampBadgeState extends State<StampBadge> {
  late Future<int> _imageNumber;

  @override
  void initState() {
    super.initState();
    _imageNumber = StampImageStore.instance.imageNumberFor(widget.spotId);
  }

  @override
  void didUpdateWidget(covariant StampBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spotId != widget.spotId) {
      _imageNumber = StampImageStore.instance.imageNumberFor(widget.spotId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final badgeSize =
              widget.size ??
              math.min(constraints.maxWidth, constraints.maxHeight);
          return FutureBuilder<int>(
            future: _imageNumber,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Tooltip(
                    message: 'スタンプ画像を読み込めませんでした',
                    child: Icon(
                      Icons.error_outline,
                      semanticLabel: 'スタンプ画像を読み込めませんでした',
                    ),
                  ),
                );
              }
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox.shrink();
              }
              final imageNumber = snapshot.requireData;
              // The portrait assets include generous margins around the art.
              // Scale the image and ribbon label together within the badge cell.
              return ClipRect(
                child: Transform.scale(
                  scale: imageNumber == 1 ? 1 : 1.55,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        StampImageStore.assetPath(imageNumber),
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                      Positioned(
                        left: badgeSize * (imageNumber == 1 ? 0.17 : 0.26),
                        right: badgeSize * (imageNumber == 1 ? 0.17 : 0.26),
                        bottom: badgeSize * (imageNumber == 1 ? 0.13 : 0.285),
                        height: badgeSize * (imageNumber == 1 ? 0.115 : 0.075),
                        child: CustomPaint(
                          painter: _ArchedLabelPainter(
                            text: widget.label,
                            style: TextStyle(
                              color: const Color(0xFF12265A),
                              fontSize:
                                  badgeSize * (imageNumber == 1 ? 0.075 : 0.05),
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ArchedLabelPainter extends CustomPainter {
  final String text;
  final TextStyle style;

  const _ArchedLabelPainter({required this.text, required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    if (text.isEmpty || size.isEmpty) return;

    final characters = text.runes.map(String.fromCharCode).toList();
    var fontSize = style.fontSize ?? 12;
    var painters = _painters(characters, fontSize);
    var totalWidth = _totalWidth(painters);
    final maxWidth = size.width * 0.96;

    if (totalWidth > maxWidth && totalWidth > 0) {
      fontSize *= maxWidth / totalWidth;
      painters = _painters(characters, fontSize);
      totalWidth = _totalWidth(painters);
    }

    final curveDepth = size.height * 0.22;
    final centerY = size.height * 0.46;
    var cursor = (size.width - totalWidth) / 2;

    for (final painter in painters) {
      final centerX = cursor + painter.width / 2;
      final normalizedX = ((centerX - size.width / 2) / (size.width / 2)).clamp(
        -1.0,
        1.0,
      );
      final y = centerY + curveDepth * normalizedX * normalizedX;
      final slope = 2 * curveDepth * normalizedX / (size.width / 2);

      canvas.save();
      canvas.translate(centerX, y);
      canvas.rotate(math.atan(slope));
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      canvas.restore();
      cursor += painter.width;
    }
  }

  List<TextPainter> _painters(List<String> characters, double fontSize) {
    return characters
        .map(
          (character) => TextPainter(
            text: TextSpan(
              text: character,
              style: style.copyWith(fontSize: fontSize),
            ),
            textDirection: TextDirection.ltr,
          )..layout(),
        )
        .toList(growable: false);
  }

  double _totalWidth(List<TextPainter> painters) =>
      painters.fold(0, (width, painter) => width + painter.width);

  @override
  bool shouldRepaint(covariant _ArchedLabelPainter oldDelegate) {
    return text != oldDelegate.text || style != oldDelegate.style;
  }
}

class LockedStampBadge extends StatelessWidget {
  const LockedStampBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _DashedCirclePainter(),
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.48,
            heightFactor: 0.48,
            child: Image.asset(
              'assets/images/logo_mono.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final rect = Offset.zero & size;
    const dash = 0.1;
    const gap = 0.065;
    for (double start = 0; start < 6.283; start += dash + gap) {
      canvas.drawArc(rect.deflate(2), start, dash, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
