import 'package:anitrail/features/map/models/anime_spot.dart';
import 'package:anitrail/features/stamp/screens/stamp_collection_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('小さい画面でも全ての情報がスクロールなしで表示される', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StampCollectionDetailDialog(
            spot: Spot(spotId: 'spot-1', name: 'テストスポット'),
            animeTitle: 'テストアニメのタイトル',
            stampIndex: 1,
            stampTotal: 3,
            visitCount: 2,
            obtainedAt: null,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.text('アニメ「テストアニメのタイトル」'), findsOneWidget);
    expect(find.text('訪問回数: 2回　|　最終訪問: -'), findsOneWidget);
    expect(find.text('コメントする'), findsOneWidget);
  });
}
