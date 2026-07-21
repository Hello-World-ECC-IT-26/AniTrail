import 'package:anitrail/features/map/models/anime_spot.dart';
import 'package:anitrail/features/shiori/screens/shiori_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(390, 844);
    view.devicePixelRatio = 1;
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('アニメバナーが1件のときは中央に表示する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ShioriListScreen(
          spots: [
            Spot(
              spotId: 'spot-1',
              name: '聖地1',
              animeId: 'anime-1',
              animeTitle: 'アニメ1',
            ),
          ],
        ),
      ),
    );

    final banner = find.byKey(const ValueKey('shiori-anime-visual-0'));
    expect(
      tester.getCenter(banner).dx,
      tester.getCenter(find.byType(Scaffold)).dx,
    );
    expect(find.byKey(const Key('shiori-anime-visual-list')), findsNothing);
  });

  testWidgets('アニメバナーが複数のときは横スクロールできる', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ShioriListScreen(
          spots: [
            Spot(
              spotId: 'spot-1',
              name: '聖地1',
              animeId: 'anime-1',
              animeTitle: 'アニメ1',
            ),
            Spot(
              spotId: 'spot-2',
              name: '聖地2',
              animeId: 'anime-2',
              animeTitle: 'アニメ2',
            ),
          ],
        ),
      ),
    );

    final list = find.byKey(const Key('shiori-anime-visual-list'));
    final firstBanner = find.byKey(const ValueKey('shiori-anime-visual-0'));
    final initialX = tester.getTopLeft(firstBanner).dx;

    expect(list, findsOneWidget);
    expect(tester.widget<ListView>(list).scrollDirection, Axis.horizontal);

    await tester.drag(list, const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(firstBanner).dx, lessThan(initialX));
  });
}
