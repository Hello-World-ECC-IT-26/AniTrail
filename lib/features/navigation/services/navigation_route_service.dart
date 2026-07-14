import 'dart:convert';
import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/navigation_route.dart';

class NavigationRouteService {
  static const _valhallaEndpoint = 'https://valhalla1.openstreetmap.de/route';
  static const _walkingSpeedMetersPerSecond = 1.25;

  Future<NavigationRoute> fetchWalkingRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final response = await http.post(
      Uri.parse(_valhallaEndpoint),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'locations': [
          {'lat': origin.latitude, 'lon': origin.longitude},
          {'lat': destination.latitude, 'lon': destination.longitude},
        ],
        'costing': 'pedestrian',
        'directions_options': {'units': 'kilometers'},
        'shape_format': 'polyline6',
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Valhalla status ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['error'] != null) {
      final error = json['error'] as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Valhalla route error');
    }
    final trip = json['trip'] as Map<String, dynamic>?;
    if (trip == null || trip['status'] != 0) {
      throw Exception(trip?['status_message'] ?? 'ルートが見つかりません');
    }
    final legs = trip['legs'] as List<dynamic>? ?? const [];
    if (legs.isEmpty) throw Exception('ルートが見つかりません');

    final leg = legs.first as Map<String, dynamic>;
    final points = _decodePolyline(leg['shape'] as String?, precision: 6);
    if (points.length < 2) throw Exception('ルート形状が取得できません');

    final summary = trip['summary'] as Map<String, dynamic>?;
    final distance = ((summary?['length'] as num?)?.toDouble() ?? 0) * 1000;
    final duration = (summary?['time'] as num?)?.toDouble();
    return NavigationRoute(
      points: points,
      distanceMeters: distance > 0 ? distance : null,
      durationSeconds: duration ?? _walkingDuration(distance),
    );
  }

  List<LatLng> _decodePolyline(String? encoded, {required int precision}) {
    if (encoded == null || encoded.isEmpty) return const [];
    final points = <LatLng>[];
    final factor = math.pow(10, precision).toDouble();
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      final deltaLat = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lat += deltaLat;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      final deltaLng = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lng += deltaLng;

      points.add(LatLng(lat / factor, lng / factor));
    }
    return points;
  }

  double? _walkingDuration(double? meters) {
    if (meters == null || meters <= 0) return null;
    return meters / _walkingSpeedMetersPerSecond;
  }
}
