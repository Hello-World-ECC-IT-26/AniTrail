import 'package:anitrail/features/spot/widgets/spot_photo_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({
  String? streetViewUrl = 'https://example.invalid/street-view.jpg',
  List<String> userPhotoUrls = const [
    'https://example.invalid/user-new.jpg',
    'https://example.invalid/user-old.jpg',
  ],
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: SpotPhotoGallery(
          streetViewUrl: streetViewUrl,
          userPhotoUrls: userPhotoUrls,
          streetViewHeaders: const {'Authorization': 'Bearer test'},
        ),
      ),
    ),
  );
}

void main() {
  test('Street Viewを先頭に固定し、重複URLを除去する', () {
    final photos = orderedSpotPhotos(
      streetViewUrl: 'street',
      userPhotoUrls: const ['user-new', 'street', 'user-old', 'user-new'],
      streetViewHeaders: const {'Authorization': 'Bearer test'},
    );

    expect(photos.map((photo) => photo.url), [
      'street',
      'user-new',
      'user-old',
    ]);
    expect(photos.first.kind, SpotPhotoKind.streetView);
    expect(photos.first.httpHeaders, {'Authorization': 'Bearer test'});
    expect(photos.skip(1).every((photo) => !photo.isStreetView), isTrue);
  });

  test('Street Viewがない場合だけユーザー写真を先頭にする', () {
    final photos = orderedSpotPhotos(
      userPhotoUrls: const ['user-new', 'user-old'],
    );

    expect(photos.map((photo) => photo.url), ['user-new', 'user-old']);
    expect(photos.first.kind, SpotPhotoKind.user);
  });

  testWidgets('320px幅でも大画像とサムネイルを表示してオーバーフローしない', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.byKey(const ValueKey('spot-photo-main')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('spot-photo-thumbnail-0')),
      findsOneWidget,
    );
    expect(find.text('3枚'), findsOneWidget);
    expect(find.text('Street View'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('全画面ビューをスワイプして閉じられる', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('spot-photo-main')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('spot-photo-viewer-pages')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('spot-photo-viewer-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('spot-photo-viewer-pages')), findsNothing);
  });
}
