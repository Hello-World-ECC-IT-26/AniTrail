import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum NavigationDirectionAlignment { aligned, misaligned, unavailable }

const navigationDirectionToleranceDegrees = 20.0;

double normalizeDirectionDegrees(double degrees) {
  final normalized = degrees % 360;
  return normalized < 0 ? normalized + 360 : normalized;
}

double relativeDirectionDegrees({
  required double bearingDegrees,
  required double deviceHeadingDegrees,
}) {
  return normalizeDirectionDegrees(bearingDegrees - deviceHeadingDegrees);
}

double angularDifferenceDegrees(double first, double second) {
  final difference =
      (normalizeDirectionDegrees(first) - normalizeDirectionDegrees(second))
          .abs();
  return math.min(difference, 360 - difference);
}

NavigationDirectionAlignment navigationDirectionAlignment({
  required double? routeBearingDegrees,
  required double? deviceHeadingDegrees,
}) {
  if (routeBearingDegrees == null ||
      deviceHeadingDegrees == null ||
      !routeBearingDegrees.isFinite ||
      !deviceHeadingDegrees.isFinite) {
    return NavigationDirectionAlignment.unavailable;
  }

  return angularDifferenceDegrees(routeBearingDegrees, deviceHeadingDegrees) <=
          navigationDirectionToleranceDegrees
      ? NavigationDirectionAlignment.aligned
      : NavigationDirectionAlignment.misaligned;
}

/// Returns the bearing of the route segment closest to [currentLocation].
/// Equal-distance segments prefer the later segment, which points forward at
/// a route corner.
double? walkingRouteBearingAtLocation({
  required LatLng currentLocation,
  required List<LatLng> routePoints,
}) {
  if (routePoints.length < 2) return null;

  final latitudeScale = 111320.0;
  final longitudeScale =
      latitudeScale * math.cos(currentLocation.latitude * math.pi / 180);
  var closestSegmentIndex = -1;
  var closestDistanceSquared = double.infinity;

  for (var index = 0; index < routePoints.length - 1; index++) {
    final start = routePoints[index];
    final end = routePoints[index + 1];
    final startX =
        (start.longitude - currentLocation.longitude) * longitudeScale;
    final startY = (start.latitude - currentLocation.latitude) * latitudeScale;
    final endX = (end.longitude - currentLocation.longitude) * longitudeScale;
    final endY = (end.latitude - currentLocation.latitude) * latitudeScale;
    final segmentX = endX - startX;
    final segmentY = endY - startY;
    final segmentLengthSquared = segmentX * segmentX + segmentY * segmentY;
    if (segmentLengthSquared == 0) continue;

    final projection =
        (-(startX * segmentX + startY * segmentY) / segmentLengthSquared).clamp(
          0.0,
          1.0,
        );
    final closestX = startX + projection * segmentX;
    final closestY = startY + projection * segmentY;
    final distanceSquared = closestX * closestX + closestY * closestY;

    if (distanceSquared <= closestDistanceSquared) {
      closestDistanceSquared = distanceSquared;
      closestSegmentIndex = index;
    }
  }

  if (closestSegmentIndex < 0) return null;
  final start = routePoints[closestSegmentIndex];
  final end = routePoints[closestSegmentIndex + 1];
  return normalizeDirectionDegrees(
    Geolocator.bearingBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    ),
  );
}
