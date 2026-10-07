import 'package:anitrail/features/map/models/anime_spot.dart';
import 'package:anitrail/features/map/models/tour_plan.dart';
import 'package:anitrail/features/map/services/tour_plan_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const a = Spot(spotId: 'a', name: 'A', latitude: 35, longitude: 139);
const b = Spot(spotId: 'b', name: 'B', latitude: 36, longitude: 139);

void main() {
  test('復元時に重複、削除済み、座標なしの聖地を除外し順番を維持する', () {
    final plan = TourPlan(['b', 'gone', 'a', 'b', 'missing']);
    expect(plan.resolve([a, b, const Spot(spotId: 'missing', name: 'M')]), [
      b,
      a,
    ]);
    expect(
      canTourSpot(
        const Spot(spotId: 'bad', name: '', latitude: 91, longitude: 0),
      ),
      isFalse,
    );
  });
  test('端末保存は再取得でき、ユーザーとしおりごとに分離される', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalTourPlanStore();
    await store.save('u1', 'c1', TourPlan(['b', 'a']));
    expect((await LocalTourPlanStore().load('u1', 'c1')).spotIds, ['b', 'a']);
    expect((await store.load('u2', 'c1')).spotIds, isEmpty);
    expect((await store.load('u1', 'c2')).spotIds, isEmpty);
  });
  test('到着した聖地を記録して次へ進み、既存の訪問を重複集計しない', () {
    final tour = TourProgress(spots: [a, b], visitedSpotIds: {'a'});
    final next = tour.nextAfterArrival();
    expect(next.current, b);
    expect(next.visitedSpotIds, {'a'});
    expect(next.hasNext, isFalse);
    expect(() => next.nextAfterArrival(), throwsStateError);
    expect(tour.index, 0);
  });
}
