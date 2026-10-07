import 'dart:async';

import 'package:anitrail/features/home/screens/home_screen.dart';
import 'package:anitrail/features/map/models/anime_spot.dart';
import 'package:anitrail/features/map/services/spot_api.dart';
import 'package:anitrail/features/shiori/models/shiori_draft.dart';
import 'package:anitrail/features/shiori/screens/shiori_list.dart';
import 'package:anitrail/features/spot/screens/spot_detail.dart';
import 'package:anitrail/features/spot/screens/spot_list.dart';
import 'package:anitrail/features/spot/widgets/spot_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _SpotApi extends SpotApi {
  _SpotApi(this.result);
  final Future<List<Spot>> result;
  @override
  Future<List<Spot>> fetchSpots(String animeId, {double? lat, double? lng}) =>
      result;
}

class _Routes extends NavigatorObserver {
  Route<dynamic>? latest;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      latest = route;
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      latest = newRoute;
}

List<Spot> _spots(int count) => List.generate(
  count,
  (i) => Spot(spotId: 'spot-$i', name: '須賀神社$i', address: '東京都新宿区須賀町5-6'),
);

Future<void> _show(
  WidgetTester tester, {
  double width = 440,
  double scale = 1,
  Future<List<Spot>>? result,
  _Routes? observer,
  String title = '君の名は。',
}) async {
  tester.view.physicalSize = Size(width, 956);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      navigatorObservers: [?observer],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: SpotList(
        animeId: 'anime-1',
        animeTitle: title,
        spotCount: 10,
        api: _SpotApi(result ?? Future.value(_spots(10))),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() => ShioriDraft.instance.clear());
  tearDown(() {
    ShioriDraft.instance.clear();
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  for (final width in [440.0, 320.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('一覧全体が幅$width・文字倍率$scaleで収まる', (tester) async {
        await _show(tester, width: width, scale: scale);
        expect(tester.takeException(), isNull);
        expect(find.text('聖地一覧'), findsOneWidget);
        final action = tester.getRect(find.text('旅のしおりを作成'));
        final nav = tester.getRect(find.byType(BottomNavigationBar));
        expect(action.bottom, lessThan(nav.top));
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -3000),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final last = find.byWidgetPredicate(
          (w) => w is SpotListCard && w.spot.spotId == 'spot-9',
        );
        await tester.ensureVisible(last);
        await tester.pumpAndSettle();
        expect(tester.getRect(last).bottom, lessThan(action.top));
      });
    }
  }

  testWidgets('長い作品名と住所でも文字拡大時に収まる', (tester) async {
    await _show(
      tester,
      width: 320,
      scale: 2,
      title: 'とても長いアニメ作品名とその続編のタイトルを表示するテスト',
      result: Future.value([
        const Spot(
          spotId: 'long',
          name: '須賀神社とアニメに登場する周辺の長い名前の聖地',
          address: '東京都新宿区須賀町5-6 とても長い住所の建物名と部屋番号',
        ),
      ]),
    );
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('未選択時は案内し、追加・解除とバッジを同期する', (tester) async {
    await _show(tester);
    await tester.tap(find.text('旅のしおりを作成'));
    await tester.pump();
    expect(find.text('聖地を「+追加」してから作成してください'), findsOneWidget);
    await tester.tap(find.text('追加').first);
    await tester.pump();
    expect(ShioriDraft.instance.spots.value.single.animeId, 'anime-1');
    expect(find.text('追加済み'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    await tester.tap(find.text('追加済み'));
    await tester.pump();
    expect(ShioriDraft.instance.spots.value, isEmpty);
    expect(find.text('追加済み'), findsNothing);
    expect(find.text('1'), findsNothing);
  });

  testWidgets('詳細遷移に作品と聖地を渡す', (tester) async {
    final routes = _Routes();
    await _show(tester, observer: routes);
    await tester.tap(find.text('須賀神社0'));
    final route = routes.latest! as MaterialPageRoute;
    final detail =
        route.builder(tester.element(find.byType(SpotList)))
            as SpotDetailScreen;
    expect(detail.spot.spotId, 'spot-0');
    expect(detail.animeTitle, '君の名は。');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('選択した聖地でしおり作成画面を開く', (tester) async {
    await _show(tester);
    await tester.tap(find.text('追加').first);
    await tester.pump();
    await tester.tap(find.text('旅のしおりを作成'));
    await tester.pumpAndSettle();
    final shiori = tester.widget<ShioriListScreen>(
      find.byType(ShioriListScreen),
    );
    expect(shiori.spots.single.spotId, 'spot-0');
    expect(tester.takeException(), isNull);
  });

  for (final (index, label) in ['ホーム', 'マップ', 'スタンプ', 'クーポン'].indexed) {
    testWidgets('$labelは対応するタブへ遷移する', (tester) async {
      final routes = _Routes();
      await _show(tester, observer: routes);
      await tester.tap(find.text(label));
      final route = routes.latest! as MaterialPageRoute;
      final home =
          route.builder(tester.element(find.byType(SpotList))) as HomeScreen;
      expect(home.initialIndex, index);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('読み込み・空一覧・通信エラーを表示する', (tester) async {
    final pending = Completer<List<Spot>>();
    await _show(tester, result: pending.future);
    expect(find.text('聖地を読み込んでいます・・・'), findsOneWidget);
    pending.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('聖地が登録されていません'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    final failure = Completer<List<Spot>>();
    await _show(tester, result: failure.future);
    failure.completeError(Exception('network'));
    await tester.pumpAndSettle();
    expect(find.text('聖地の取得に失敗しました。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
