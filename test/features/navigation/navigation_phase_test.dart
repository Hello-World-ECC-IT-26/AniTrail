import 'package:anitrail/features/navigation/models/navigation_phase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('探索モードの既定距離は100m', () {
    expect(navigationDirectionDistanceMeters, 100);
  });

  test('設定された距離以内で方向案内、20m以内で到着へ切り替わる', () {
    final directionDistance = navigationDirectionDistanceMeters;

    expect(navigationPhaseForDistance(null), NavigationPhase.route);
    expect(
      navigationPhaseForDistance(directionDistance + 0.1),
      NavigationPhase.route,
    );
    expect(
      navigationPhaseForDistance(directionDistance),
      NavigationPhase.direction,
    );
    expect(navigationPhaseForDistance(20.1), NavigationPhase.direction);
    expect(navigationPhaseForDistance(20), NavigationPhase.arrived);
    expect(navigationPhaseForDistance(0), NavigationPhase.arrived);
  });

  test('20m内外を連続しても到着遷移は一度だけ確保される', () {
    final guard = ArrivalEntryGuard();

    expect(guard.claim(NavigationPhase.direction), isFalse);
    expect(guard.claim(NavigationPhase.arrived), isTrue);
    expect(guard.claim(NavigationPhase.direction), isFalse);
    expect(guard.claim(NavigationPhase.arrived), isFalse);
  });
}
