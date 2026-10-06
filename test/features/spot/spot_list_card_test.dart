import 'package:anitrail/core/widgets/main_buttom_nav.dart';
import 'package:anitrail/features/map/models/anime_spot.dart';
import 'package:anitrail/features/spot/widgets/spot_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const longSpot = Spot(
    spotId: 'spot-1',
    name: '須賀神社とアニメに登場する周辺の長い名前の聖地',
    address: '東京都新宿区須賀町5-6 とても長い住所の建物名と部屋番号',
  );

  for (final width in [440.0, 320.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('幅$width・文字倍率$scaleでカードと操作が収まる', (tester) async {
        tester.view.physicalSize = Size(width, 956);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var added = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 956),
                textScaler: TextScaler.linear(scale),
              ),
              child: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SpotListCard(
                    spot: longSpot,
                    animeTitle: 'とても長いアニメ作品タイトルを表示するテスト',
                    thumbnail: const ColoredBox(color: Colors.green),
                    selected: false,
                    onAdd: () => added++,
                    onOpen: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final cardRect = tester.getRect(find.byType(SpotListCard));
        final buttonRect = tester.getRect(find.byType(ElevatedButton));
        expect(buttonRect.height, greaterThanOrEqualTo(44));
        expect(cardRect.contains(buttonRect.bottomRight), isTrue);
        await tester.tap(find.text('追加'));
        expect(added, 1);
      });
    }
  }

  testWidgets('画像と本文から詳細を開き、追加タップは詳細を開かない', (tester) async {
    var opened = 0;
    var added = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpotListCard(
            spot: longSpot,
            animeTitle: '作品',
            thumbnail: const ColoredBox(
              key: ValueKey('photo'),
              color: Colors.green,
            ),
            selected: false,
            onAdd: () => added++,
            onOpen: () => opened++,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('photo')));
    await tester.tap(find.text(longSpot.name));
    expect(opened, 2);
    await tester.tap(find.text('追加'));
    expect(added, 1);
    expect(opened, 2);
  });

  testWidgets('選択済みの追加ボタンを解除に使える', (tester) async {
    var removed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpotListCard(
            spot: longSpot,
            animeTitle: '作品',
            thumbnail: const SizedBox(),
            selected: true,
            onAdd: () => removed = true,
            onOpen: () {},
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.tap(find.text('追加済み'));
    expect(removed, isTrue);
  });

  testWidgets('ナビの色と影を画面ごとに指定でき、既定値も維持する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(bottomNavigationBar: MainBottomNav(onTap: (_) {})),
      ),
    );
    var nav = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(nav.unselectedItemColor, Colors.grey);
    expect(nav.elevation, 8);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MainBottomNav(
            itemColor: Colors.black,
            elevation: 0,
            onTap: (_) {},
          ),
        ),
      ),
    );
    nav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(nav.selectedItemColor, Colors.black);
    expect(nav.unselectedItemColor, Colors.black);
    expect(nav.elevation, 0);
  });
}
