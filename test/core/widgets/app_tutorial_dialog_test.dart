import 'package:anitrail/core/widgets/app_tutorial_dialog.dart';
import 'package:anitrail/features/home/widgets/home_tutorial.dart'
    as home_tutorial;
import 'package:anitrail/features/map/widgets/map_tutorial.dart'
    as map_tutorial;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pages = [
  AppTutorialPage(
    title: '1ページ',
    description: '1ページの説明',
    imageAsset: 'assets/images/logo.svg',
  ),
  AppTutorialPage(
    title: '2ページ',
    description: '2ページの説明',
    imageAsset: 'assets/images/logo.svg',
  ),
  AppTutorialPage(
    title: '3ページ',
    description: '3ページの説明',
    imageAsset: 'assets/images/logo.svg',
  ),
  AppTutorialPage(
    title: '4ページ',
    description: '4ページの説明',
    imageAsset: 'assets/images/logo.svg',
  ),
];

const _svgAssets = [
  'assets/images/home_tutorial1.svg',
  'assets/images/home_tutorial2.svg',
  'assets/images/home_tutorial3.svg',
  'assets/images/home_tutorial4.svg',
  'assets/images/map_tutorial1.svg',
  'assets/images/map_tutorial2.svg',
  'assets/images/map_tutorial3.svg',
  'assets/images/map_tutorial4.svg',
];

void main() {
  testWidgets('ホーム・マップの全SVGが空データにならない', (tester) async {
    for (final asset in _svgAssets) {
      final bytes = await tester.runAsync(
        () => SvgAssetLoader(asset).loadBytes(null),
      );
      expect(bytes!.lengthInBytes, greaterThan(1000), reason: asset);
    }
  });

  testWidgets('画像と説明文の両方から左右スワイプで移動できる', (tester) async {
    await _pumpTutorial(tester);

    await tester.drag(
      find.byKey(const ValueKey('tutorial-description-0')),
      const Offset(-260, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('2ページ'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('tutorial-image-1')),
      const Offset(260, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('1ページ'), findsOneWidget);
  });

  testWidgets('内容タップで次へ進み、丸から任意ページへ移動できる', (tester) async {
    await _pumpTutorial(tester);

    await tester.tap(find.byKey(const ValueKey('tutorial-page-0')));
    await tester.pumpAndSettle();
    expect(find.text('2ページ'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tutorial-indicator-3')));
    await tester.pumpAndSettle();
    expect(find.text('4ページ'), findsOneWidget);
  });

  testWidgets('最終ページは通常タップで閉じず、完了ボタンで閉じる', (tester) async {
    await _pumpTutorial(tester, openAsDialog: true);

    await tester.tap(find.byKey(const ValueKey('tutorial-indicator-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tutorial-page-3')));
    await tester.pumpAndSettle();
    expect(find.byType(AppTutorialDialog), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tutorial-complete')));
    await tester.pumpAndSettle();
    expect(find.byType(AppTutorialDialog), findsNothing);
  });

  testWidgets('320px幅の小型画面でもオーバーフローしない', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const tutorials = <Widget>[
      home_tutorial.TutorialDialog(),
      map_tutorial.TutorialDialog(),
    ];
    for (final tutorial in tutorials) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: tutorial)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tutorial-indicator-3')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('tutorial-complete')), findsOneWidget);
    }
  });

  testWidgets('マップチュートリアルは初回だけ表示する', (tester) async {
    SharedPreferences.setMockInitialValues({});
    late BuildContext hostContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const Scaffold();
          },
        ),
      ),
    );

    final firstDisplay = map_tutorial.showMapTutorialIfNeeded(hostContext);
    await tester.pumpAndSettle();
    expect(find.text('聖地巡礼の流れ'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tutorial-skip')));
    await tester.pumpAndSettle();
    expect(await firstDisplay, isTrue);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(map_tutorial.mapTutorialShownKey), isTrue);

    expect(await map_tutorial.showMapTutorialIfNeeded(hostContext), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('聖地巡礼の流れ'), findsNothing);
  });
}

Future<void> _pumpTutorial(
  WidgetTester tester, {
  bool openAsDialog = false,
}) async {
  if (!openAsDialog) {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppTutorialDialog(heading: 'アプリ説明', pages: _pages),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return;
  }

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const AppTutorialDialog(heading: 'アプリ説明', pages: _pages),
              ),
              child: const Text('開く'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('開く'));
  await tester.pumpAndSettle();
}
