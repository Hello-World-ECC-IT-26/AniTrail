import 'package:flutter/foundation.dart';

enum NavigationPhase { route, compass, arrived }

const _defaultNavigationCompassDistanceMeters = 500.0;
const navigationArrivalDistanceMeters = 20.0;
const _debugNavigationCompassDistance = String.fromEnvironment(
  'DEBUG_NAVIGATION_COMPASS_DISTANCE_METERS',
);

/// 探索モードへ切り替える目的地からの距離。
///
/// デバッグビルドでのみ、例えば
/// `--dart-define=DEBUG_NAVIGATION_COMPASS_DISTANCE_METERS=5000`
/// のように起動時の値を上書きできる。
double get navigationCompassDistanceMeters {
  final debugDistance = double.tryParse(_debugNavigationCompassDistance);

  if (kDebugMode &&
      debugDistance != null &&
      debugDistance.isFinite &&
      debugDistance > navigationArrivalDistanceMeters) {
    return debugDistance;
  }
  return _defaultNavigationCompassDistanceMeters;
}

NavigationPhase navigationPhaseForDistance(double? distanceMeters) {
  if (distanceMeters == null ||
      distanceMeters.isNaN ||
      distanceMeters.isInfinite) {
    return NavigationPhase.route;
  }
  if (distanceMeters <= navigationArrivalDistanceMeters) {
    return NavigationPhase.arrived;
  }
  if (distanceMeters <= navigationCompassDistanceMeters) {
    return NavigationPhase.compass;
  }
  return NavigationPhase.route;
}

class ArrivalEntryGuard {
  bool _claimed = false;

  bool claim(NavigationPhase phase) {
    if (_claimed || phase != NavigationPhase.arrived) return false;
    _claimed = true;
    return true;
  }
}
