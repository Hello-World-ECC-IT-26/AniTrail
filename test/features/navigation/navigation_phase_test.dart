import 'package:anitrail/features/navigation/models/navigation_phase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('500m以内でコンパス、20m以内で到着へ切り替わる', () {
    expect(navigationPhaseForDistance(null), NavigationPhase.route);
    expect(navigationPhaseForDistance(500.1), NavigationPhase.route);
    expect(navigationPhaseForDistance(500), NavigationPhase.compass);
    expect(navigationPhaseForDistance(20.1), NavigationPhase.compass);
    expect(navigationPhaseForDistance(20), NavigationPhase.arrived);
    expect(navigationPhaseForDistance(0), NavigationPhase.arrived);
  });

  test('20m内外を連続しても到着遷移は一度だけ確保される', () {
    final guard = ArrivalEntryGuard();

    expect(guard.claim(NavigationPhase.compass), isFalse);
    expect(guard.claim(NavigationPhase.arrived), isTrue);
    expect(guard.claim(NavigationPhase.compass), isFalse);
    expect(guard.claim(NavigationPhase.arrived), isFalse);
  });
}
