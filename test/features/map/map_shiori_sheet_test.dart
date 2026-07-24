import 'package:anitrail/features/map/models/anime_spot.dart';
import 'package:anitrail/features/map/widgets/map_shiori_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('指定したしおりを選択した状態で表示する', (tester) async {
    const card = StampCard(
      cardId: 'card-1',
      title: '作成したしおり',
      spotCount: 0,
      spots: [],
    );
    var detailVisible = false;
    List<Spot>? shownSpots;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              MapShioriSheet(
                initialCard: card,
                loadCollections: ({bool force = false}) async => const [
                  StampCollection(card: card, visitStats: {}),
                ],
                onClose: () {},
                onShowSpots: (spots) => shownSpots = spots,
                onClearSpots: () {},
                onDetailVisibilityChanged: (visible) => detailVisible = visible,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('作成したしおり'), findsOneWidget);
    expect(find.text('聖地が登録されていません'), findsOneWidget);
    expect(detailVisible, isTrue);
    expect(shownSpots, isEmpty);
  });
}
