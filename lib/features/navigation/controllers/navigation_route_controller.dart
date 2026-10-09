import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/navigation_route.dart';
import '../models/navigation_route_distance.dart';

typedef WalkingRouteFetcher =
    Future<NavigationRoute> Function({
      required LatLng origin,
      required LatLng destination,
    });

/// Serializes initial/manual/automatic requests and detects confirmed departures.
class NavigationRouteController extends ChangeNotifier {
  NavigationRouteController({
    required this.destination,
    required WalkingRouteFetcher fetchRoute,
    DateTime Function()? now,
    this.requestTimeout = const Duration(seconds: 15),
  }) : _fetchRoute = fetchRoute,
       _now = now ?? DateTime.now;

  final LatLng destination;
  final WalkingRouteFetcher _fetchRoute;
  final DateTime Function() _now;
  final Duration requestTimeout;
  LatLng? currentLocation;
  NavigationRoute? route;
  String? error;
  bool loading = false;
  bool offRoute = false;
  bool _arrived = false;
  bool _disposed = false;
  int _departures = 0;
  DateTime? _lastStarted;

  bool get updating => loading && route != null;
  bool get guidanceUnavailable => offRoute || route == null;

  void updatePosition(
    LatLng location, {
    required double accuracy,
    required bool arrived,
  }) {
    if (_disposed || _arrived) return;
    currentLocation = location;
    _arrived = arrived;
    if (arrived) return;
    if (!accuracy.isFinite || accuracy < 0 || accuracy > 30) {
      _departures = 0;
      return;
    }
    final distance = route == null
        ? null
        : distanceToWalkingRoute(location, route!.points);
    if (distance != null && distance > 30) {
      _departures++;
      if (_departures >= 2) offRoute = true;
    } else {
      _departures = 0;
      offRoute = false;
    }
    notifyListeners();
    if (route == null || offRoute) {
      requestRoute(automatic: true);
    }
  }

  Future<void> requestRoute({bool automatic = false}) async {
    final origin = currentLocation;
    if (_disposed || _arrived || loading || origin == null) return;
    final now = _now();
    if (automatic &&
        _lastStarted != null &&
        now.difference(_lastStarted!) < const Duration(seconds: 15))
      return;
    _lastStarted = now;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _fetchRoute(
        origin: origin,
        destination: destination,
      ).timeout(requestTimeout);
      if (_disposed || _arrived) return;
      route = result;
      offRoute = false;
      _departures = 0;
    } catch (e) {
      if (_disposed || _arrived) return;
      error = '徒歩ルート作成に失敗しました: $e';
    } finally {
      loading = false;
      if (!_disposed && !_arrived) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
