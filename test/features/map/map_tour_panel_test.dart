import 'package:anitrail/features/map/models/anime_spot.dart';
import 'package:anitrail/features/map/services/tour_controller.dart';
import 'package:anitrail/features/map/widgets/map_tour_panel.dart';
import 'package:anitrail/features/map/widgets/tour_map_assets.dart';
import 'package:anitrail/features/navigation/models/navigation_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'tour_controller_test.dart' show MemoryStore;

const a = Spot(
  spotId: 'a',
  name: '歌舞伎町周辺',
  address: '東京都新宿区',
  latitude: 35,
  longitude: 139,
);
const b = Spot(spotId: 'b', name: '四ツ谷駅', latitude: 36, longitude: 139);
const card = StampCard(
  cardId: 'c',
  title: '君の名は。',
  spotCount: 2,
  spots: [a, b],
);

Future<TourController> setup() async {
  final c = TourController(
    userId: 'u',
    store: MemoryStore(),
    loadRoute: ({required origin, required destination}) async =>
        NavigationRoute(
          points: [origin, destination],
          distanceMeters: 3500,
          durationSeconds: 1200,
        ),
  );
  await c.selectCard(card);
  c.setCurrentLocation(const LatLng(34, 139));
  c.beginEditing();
  return c;
}

Widget app(
  TourController c,
  ScrollController scroll, {
  VoidCallback? onStart,
}) => MaterialApp(
  home: Scaffold(
    body: AnimatedBuilder(
      animation: c,
      builder: (context, _) => Column(
        children: [
          TourEndpoints(tour: c),
          Expanded(
            child: MapTourPanel(
              tour: c,
              scrollController: scroll,
              onClose: c.cancelEditing,
              onSpotDetail: (_) {},
              onStart: onStart ?? () {},
            ),
          ),
        ],
      ),
    ),
  ),
);

void main() {
  testWidgets('空の選択では設定を無効にし、確認取消と編集取消を区別する', (tester) async {
    final c = await setup();
    final scroll = ScrollController();
    addTearDown(c.dispose);
    addTearDown(scroll.dispose);
    await tester.pumpWidget(app(c, scroll));
    expect(find.text('巡りたい聖地を訪問する順にタップしてね'), findsOneWidget);
    c.toggle(a);
    c.toggle(b);
    await tester.pumpAndSettle();
    expect(find.text('徒歩で20分 (3.5km)'), findsNWidgets(2));
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    expect(find.text('巡る順番を設定しますか？'), findsOneWidget);
    for (final label in ['設定', 'もう少し考える']) {
      final text = find.descendant(
        of: find.byType(Dialog),
        matching: find.text(label),
      );
      final paragraph = tester.renderObject<RenderParagraph>(text);
      expect(
        paragraph.size.height,
        greaterThanOrEqualTo(
          paragraph.getMaxIntrinsicHeight(paragraph.size.width),
        ),
      );
    }
    await tester.tap(find.text('もう少し考える'));
    await tester.pumpAndSettle();
    expect(c.editing, isTrue);
    expect(c.spots, [a, b]);
    await tester.tap(find.byTooltip('変更を取り消す'));
    await tester.pumpAndSettle();
    expect(c.savedSpots, isEmpty);
  });

  testWidgets('ドラッグで並べ替えて確定するとナビ開始を表示する', (tester) async {
    final c = await setup();
    final scroll = ScrollController();
    addTearDown(c.dispose);
    addTearDown(scroll.dispose);
    c.toggle(a);
    c.toggle(b);
    var starts = 0;
    await tester.pumpWidget(app(c, scroll, onStart: () => starts++));
    await tester.pumpAndSettle();
    final drag = find.byType(ReorderableDragStartListener).first;
    final gesture = await tester.startGesture(tester.getCenter(drag));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 200));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(c.spots, [b, a]);
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, '設定').last);
    await tester.pumpAndSettle();
    expect(c.savedSpots, [b, a]);
    expect(find.text('ナビ開始'), findsOneWidget);
    await tester.tap(find.text('ナビ開始'));
    await tester.pump();
    expect(starts, 1);
  });

  testWidgets('狭い画面と文字拡大でも表示が収まり、SVGマーカーを読み込める', (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = await setup();
    final scroll = ScrollController();
    addTearDown(c.dispose);
    addTearDown(scroll.dispose);
    c.toggle(a);
    c.toggle(b);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 760),
            textScaler: TextScaler.linear(1.5),
          ),
          child: Scaffold(
            body: MapTourPanel(
              tour: c,
              scrollController: scroll,
              onClose: c.cancelEditing,
              onSpotDetail: (_) {},
              onStart: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final assets = TourMapAssets();
    await tester.runAsync(() => assets.load(5));
    expect(assets.start, isNotNull);
    expect(assets.numbered, hasLength(5));
  });
}
