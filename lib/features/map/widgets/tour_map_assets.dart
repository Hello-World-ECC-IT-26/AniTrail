import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/styles/app_styles.dart';

class TourMapAssets {
  static const walking = 'assets/images/tour/3548-8573.svg';
  static const smallFlag = 'assets/images/tour/3560-8811.svg';
  static const smallPin = 'assets/images/tour/3560-8419.svg';
  static const flag = 'assets/images/tour/3644-8859.svg';
  static const pins = [
    'assets/images/tour/3644-8907.svg',
    'assets/images/tour/3644-9048.svg',
    'assets/images/tour/3644-9054.svg',
    'assets/images/tour/3644-9063.svg',
  ];
  final Map<int, BitmapDescriptor> numbered = {};
  BitmapDescriptor? start;

  Future<void> load(int count) async {
    start ??= await _bitmap(flag);
    for (var i = 0; i < count; i++) {
      numbered[i] ??= i < pins.length
          ? await _bitmap(pins[i])
          : await _bitmap(smallPin, number: i + 1);
    }
  }

  Future<BitmapDescriptor> _bitmap(String asset, {int? number}) async {
    final info = await vg.loadPicture(SvgAssetLoader(asset), null);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(3);
    final size = number == null ? info.size : const Size(40, 34);
    canvas.drawPicture(info.picture);
    if (number != null) {
      // The number is session data; the exported SVG itself is unchanged.
      canvas.drawCircle(
        const Offset(27, 12),
        11,
        Paint()..color = AppColors.tourSurface,
      );
      canvas.drawCircle(
        const Offset(27, 12),
        11,
        Paint()
          ..color = AppColors.tourPrimary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      final text = TextPainter(
        text: TextSpan(
          text: '$number',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.tourPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(27 - text.width / 2, 12 - text.height / 2));
    }
    final picture = recorder.endRecording();
    final raster = await picture.toImage(
      (size.width * 3).ceil(),
      (size.height * 3).ceil(),
    );
    final bytes = await raster.toByteData(format: ui.ImageByteFormat.png);
    info.picture.dispose();
    picture.dispose();
    raster.dispose();
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: 3,
    );
  }
}
