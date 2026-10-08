import 'dart:io';
import 'dart:ui' as ui;

import 'package:anitrail/features/stamp/widgets/stamp_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'renders all four assets with spot labels and retains selection on rebuild',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        for (var n = 1; n <= 4; n++) 'stamp_image_v1.spot-$n': n,
      });
      tester.view.physicalSize = const Size(1000, 300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundaryKey = GlobalKey();
      Widget preview() => MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: boundaryKey,
            child: Row(
              children: [
                for (var n = 1; n <= 4; n++)
                  StampBadge(spotId: 'spot-$n', label: '須賀神社', size: 240),
              ],
            ),
          ),
        ),
      );
      await tester.pumpWidget(preview());
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(StampBadge).first);
        for (var n = 1; n <= 4; n++) {
          await precacheImage(
            AssetImage('assets/images/stamp0$n.png'),
            context,
          );
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widgetList<RawImage>(find.byType(RawImage))
            .every((image) => image.image != null),
        isTrue,
      );
      final paths = tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => (image.image as AssetImage).assetName)
          .toList();
      expect(paths, [
        for (var n = 1; n <= 4; n++) 'assets/images/stamp0$n.png',
      ]);
      expect(
        find.descendant(
          of: find.byType(StampBadge),
          matching: find.byType(CustomPaint),
        ),
        findsNWidgets(4),
      );
      // Optional artifact for local visual inspection; normal test runs write nothing.
      const output = String.fromEnvironment('STAMP_PREVIEW_PATH');
      if (output.isNotEmpty) {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(output).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(preview());
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<Image>(find.byType(Image))
            .map((image) => (image.image as AssetImage).assetName),
        paths,
      );
    },
  );

  testWidgets(
    'changing the spot updates the asset and invalid saved data shows an error',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'stamp_image_v1.first': 1,
        'stamp_image_v1.second': 4,
        'stamp_image_v1.invalid': 0,
      });
      Widget badge(String spotId) => MaterialApp(
        home: Center(
          child: StampBadge(spotId: spotId, label: '聖地名', size: 120),
        ),
      );
      await tester.pumpWidget(badge('first'));
      await tester.pumpAndSettle();
      expect(
        (tester.widget<Image>(find.byType(Image)).image as AssetImage)
            .assetName,
        'assets/images/stamp01.png',
      );
      await tester.pumpWidget(badge('second'));
      await tester.pumpAndSettle();
      expect(
        (tester.widget<Image>(find.byType(Image)).image as AssetImage)
            .assetName,
        'assets/images/stamp04.png',
      );
      await tester.pumpWidget(badge('invalid'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
