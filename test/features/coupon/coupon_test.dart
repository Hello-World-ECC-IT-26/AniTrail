import 'package:anitrail/features/coupon/models/coupon.dart';
import 'package:anitrail/features/coupon/widgets/coupon_ticket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Coupon _coupon({bool unlocked = true, DateTime? usedAt}) => Coupon(
  id: 'coupon-1',
  title: 'テストクーポン',
  category: CouponCategory.drinkFood,
  discountPercent: 10,
  description: 'テスト',
  startsAt: DateTime.utc(2026, 1, 1),
  endsAt: DateTime.utc(2026, 10, 31),
  unlocked: unlocked,
  visitedCount: unlocked ? 3 : 2,
  totalSpotCount: 5,
  requiredVisitCount: 3,
  remainingCount: unlocked ? 0 : 1,
  progressPercent: unlocked ? 60 : 40,
  usedAt: usedAt,
);

void main() {
  test('APIの進捗フィールドを型付きモデルへ復元できる', () {
    final coupon = Coupon.fromJson({
      'id': 'coupon-1',
      'title': 'テストクーポン',
      'category': 'anime_goods',
      'discount_percent': 20,
      'starts_at': '2026-01-01T00:00:00Z',
      'ends_at': '2026-10-31T00:00:00Z',
      'unlocked': false,
      'visited_count': 2,
      'total_spot_count': 5,
      'required_visit_count': 3,
      'remaining_count': 1,
      'progress_percent': 40,
    });

    expect(coupon.category, CouponCategory.animeGoods);
    expect(coupon.remainingCount, 1);
    expect(coupon.unlocked, isFalse);
  });

  testWidgets('320px幅でもロック中の券面がオーバーフローしない', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: CouponTicketCard(coupon: _coupon(unlocked: false)),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('訪問 2/5・あと1か所'), findsOneWidget);
  });

  testWidgets('利用済み券面を明示する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CouponTicketCard(
            coupon: _coupon(usedAt: DateTime.utc(2026, 7, 20)),
          ),
        ),
      ),
    );

    expect(find.text('利用済み'), findsOneWidget);
  });
}
