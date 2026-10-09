import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Distance to the closest point on the route, including segment interiors.
double? distanceToWalkingRoute(LatLng location, List<LatLng> points) {
  if (points.length < 2) return null;
  const latitudeScale = 111320.0;
  final longitudeScale =
      latitudeScale * math.cos(location.latitude * math.pi / 180);
  var closestSquared = double.infinity;
  for (var i = 0; i < points.length - 1; i++) {
    final x = (points[i].longitude - location.longitude) * longitudeScale;
    final y = (points[i].latitude - location.latitude) * latitudeScale;
    final dx = (points[i + 1].longitude - points[i].longitude) * longitudeScale;
    final dy = (points[i + 1].latitude - points[i].latitude) * latitudeScale;
    final lengthSquared = dx * dx + dy * dy;
    final t = lengthSquared == 0
        ? 0.0
        : (-(x * dx + y * dy) / lengthSquared).clamp(0.0, 1.0);
    final distanceSquared = math.pow(x + t * dx, 2) + math.pow(y + t * dy, 2);
    closestSquared = math.min(closestSquared, distanceSquared.toDouble());
  }
  return math.sqrt(closestSquared);
}
