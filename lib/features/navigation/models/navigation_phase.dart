enum NavigationPhase { route, compass, arrived }

const navigationCompassDistanceMeters = 500.0;
const navigationArrivalDistanceMeters = 20.0;

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
