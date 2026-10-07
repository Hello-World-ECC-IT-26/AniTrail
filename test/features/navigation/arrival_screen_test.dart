import 'dart:async';

import 'package:anitrail/features/coupon/models/coupon.dart';
import 'package:anitrail/features/map/models/anime_spot.dart';
import 'package:anitrail/features/map/models/tour_plan.dart';
import 'package:anitrail/features/map/services/spot_api.dart';
import 'package:anitrail/features/navigation/screens/arrival_screen_mobile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSpotApi extends SpotApi {
  _FakeSpotApi({this.failFirst = false});

  final bool failFirst;
  final List<String> stampIds = [];
  Completer<StampCreationResult>? pending;

  @override
  Future<StampCreationResult> createArrivalStamp({
    required String cardId,
    required String spotId,
    required String stampId,
    required DateTime obtainedAt,
    List<int>? imageBytes,
    String? imageFilename,
    String? imageContentType,
  }) async {
    stampIds.add(stampId);
    if (failFirst && stampIds.length == 1) throw Exception('upload failed');
    final completer = pending;
    if (completer != null) return completer.future;
    return StampCreationResult(stampId: stampId, newGrants: const []);
  }
}

Widget _app(
  SpotApi api, {
  TourProgress? tour,
  Widget Function(TourProgress)? nextBuilder,
}) => MaterialApp(
  home: ArrivalScreen(
    tour: tour,
    nextNavigationBuilder: nextBuilder,
    spot:
        tour?.current ??
        const Spot(
          spotId: '10000000-0000-4000-8000-000000000001',
          name: 'テスト聖地',
          animeTitle: 'テストアニメ',
        ),
    cardId: '20000000-0000-4000-8000-000000000001',
    stampCount: 0,
    stampTotal: 3,
    spotApi: api,
  ),
);

void main() {
  testWidgets('到着時に余分な次へ画面を挟まず獲得方法を選べる', (tester) async {
    await tester.pumpWidget(_app(_FakeSpotApi()));

    expect(find.text('聖地に到着！'), findsOneWidget);
    expect(find.text('写真を撮って獲得'), findsOneWidget);
    expect(find.text('写真なしで獲得'), findsOneWidget);
    expect(find.text('つぎへ'), findsNothing);
  });

  testWidgets('送信ボタンを連打しても到着APIは一度だけ呼ばれる', (tester) async {
    final api = _FakeSpotApi()..pending = Completer<StampCreationResult>();
    await tester.pumpWidget(_app(api));

    await tester.ensureVisible(find.text('写真なしで獲得'));
    await tester.tap(find.text('写真なしで獲得'));
    await tester.tap(find.text('写真なしで獲得'), warnIfMissed: false);
    await tester.pump();

    expect(api.stampIds, hasLength(1));
    expect(find.text('スタンプと写真を保存しています・・・'), findsOneWidget);

    api.pending!.complete(
      StampCreationResult(stampId: api.stampIds.single, newGrants: const []),
    );
    await tester.pumpAndSettle();
    expect(find.text('スタンプ獲得！'), findsOneWidget);
  });

  testWidgets('失敗後の再試行でも同じstamp_idを使用する', (tester) async {
    final api = _FakeSpotApi(failFirst: true);
    await tester.pumpWidget(_app(api));

    await tester.ensureVisible(find.text('写真なしで獲得'));
    await tester.tap(find.text('写真なしで獲得'));
    await tester.pumpAndSettle();
    expect(find.text('保存できませんでした'), findsOneWidget);

    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();

    expect(api.stampIds, hasLength(2));
    expect(api.stampIds.first, api.stampIds.last);
    expect(find.text('スタンプ獲得！'), findsOneWidget);
  });

  testWidgets('巡回では保存成功後だけ次の聖地へ進み、連打でも一度だけ遷移する', (tester) async {
    const first = Spot(spotId: 'first', name: '最初の聖地');
    const second = Spot(spotId: 'second', name: '次の聖地');
    final api = _FakeSpotApi(failFirst: true);
    TourProgress? continued;
    var transitions = 0;
    await tester.pumpWidget(
      _app(
        api,
        tour: TourProgress(spots: [first, second]),
        nextBuilder: (next) {
          continued = next;
          transitions++;
          return Scaffold(body: Text(next.current.name));
        },
      ),
    );
    expect(find.text('次の聖地へ'), findsNothing);
    await tester.ensureVisible(find.text('写真なしで獲得'));
    await tester.tap(find.text('写真なしで獲得'));
    await tester.pumpAndSettle();
    expect(find.text('次の聖地へ'), findsNothing);
    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('次の聖地へ'));
    await tester.tap(find.text('次の聖地へ'));
    await tester.tap(find.text('次の聖地へ'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('次の聖地'), findsOneWidget);
    expect(continued?.index, 1);
    expect(continued?.visitedSpotIds, {'first'});
    expect(transitions, 1);
  });

  testWidgets('最後の聖地は次の案内を表示せず、しおりに戻れる', (tester) async {
    const last = Spot(spotId: 'last', name: '最後の聖地');
    await tester.pumpWidget(
      _app(_FakeSpotApi(), tour: TourProgress(spots: [last])),
    );
    await tester.ensureVisible(find.text('写真なしで獲得'));
    await tester.tap(find.text('写真なしで獲得'));
    await tester.pumpAndSettle();
    expect(find.text('次の聖地へ'), findsNothing);
    expect(find.text('しおりに戻る'), findsOneWidget);
    expect(find.text('閉じる'), findsNothing);
  });

  testWidgets('スタンプ獲得画面の背景が端末幅いっぱいに表示される', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(_FakeSpotApi()));
    await tester.ensureVisible(find.text('写真なしで獲得'));
    await tester.tap(find.text('写真なしで獲得'));
    await tester.pumpAndSettle();

    final background = tester.getSize(
      find.byKey(const ValueKey('arrival-earned-background')),
    );
    expect(background.width, 360);
    expect(background.height, 800);
    expect(tester.takeException(), isNull);
  });
}
