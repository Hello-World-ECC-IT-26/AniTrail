import 'package:anitrail/core/data/app_data_repository.dart';
import 'package:anitrail/features/home/models/app_event.dart';
import 'package:anitrail/features/home/screens/event_detail_screen.dart';
import 'package:anitrail/features/home/widgets/event_section.dart';
import 'package:anitrail/features/map/services/spot_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test('イベントAPIのデータを復元できる', () {
    final event = AppEvent.fromJson({
      'id': 'event-1',
      'title': 'テストイベント',
      'summary': '概要',
      'content': '詳細',
      'banner_url': 'https://example.com/event.png',
      'starts_at': '2026-07-01T00:00:00Z',
      'ends_at': '2026-07-31T23:59:59Z',
    });

    expect(event.title, 'テストイベント');
    expect(event.startsAt, DateTime.utc(2026, 7));
    expect(event.bannerUrl, 'https://example.com/event.png');
  });

  testWidgets('開催中イベント0件ならセクションを表示しない', (tester) async {
    final repository = AppDataRepository(SpotApi());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: repository,
        child: const MaterialApp(home: Scaffold(body: EventSection())),
      ),
    );

    expect(find.text('期間限定イベント開催中！'), findsNothing);
  });

  testWidgets('イベントをタップすると詳細を表示する', (tester) async {
    final repository = AppDataRepository(SpotApi())
      ..activeEvents = [
        AppEvent(
          id: 'event-1',
          title: 'テストイベント',
          summary: 'イベントの概要',
          content: 'イベントの詳細情報',
          startsAt: DateTime.utc(2026, 7, 1),
          endsAt: DateTime.utc(2026, 7, 31),
        ),
      ];
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: repository,
        child: const MaterialApp(home: Scaffold(body: EventSection())),
      ),
    );

    await tester.tap(find.text('テストイベント'));
    await tester.pumpAndSettle();

    expect(find.byType(EventDetailScreen), findsOneWidget);
    expect(find.text('イベントの概要'), findsOneWidget);
    expect(find.text('イベントの詳細情報'), findsOneWidget);
  });
}
