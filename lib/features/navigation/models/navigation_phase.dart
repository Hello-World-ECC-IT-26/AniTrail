import 'package:flutter/foundation.dart';

enum NavigationPhase { route, direction, arrived }

const _defaultNavigationDirectionDistanceMeters = 500.0;
const navigationArrivalDistanceMeters = 20.0;
const _debugNavigationDirectionDistance = String.fromEnvironment(
  'DEBUG_NAVIGATION_DIRECTION_DISTANCE_METERS',
);
const _legacyDebugNavigationCompassDistance = String.fromEnvironment(
  'DEBUG_NAVIGATION_COMPASS_DISTANCE_METERS',
);

/// 方向案内モードへ切り替える目的地からの距離。
///
/// デバッグビルドでのみ、例えば
/// `--dart-define=DEBUG_NAVIGATION_DIRECTION_DISTANCE_METERS=5000`
/// のように起動時の値を上書きできる。
double get navigationDirectionDistanceMeters {
  final debugDistance =
      double.tryParse(_debugNavigationDirectionDistance) ??
      double.tryParse(_legacyDebugNavigationCompassDistance);

  if (kDebugMode &&
      debugDistance != null &&
      debugDistance.isFinite &&
      debugDistance > navigationArrivalDistanceMeters) {
    return debugDistance;
  }
  return _defaultNavigationDirectionDistanceMeters;
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
  if (distanceMeters <= navigationDirectionDistanceMeters) {
    return NavigationPhase.direction;
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
