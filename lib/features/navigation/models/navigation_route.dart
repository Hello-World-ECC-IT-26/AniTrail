import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationRoute {
  final List<LatLng> points;
  final double? distanceMeters;
  final double? durationSeconds;

  const NavigationRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}
