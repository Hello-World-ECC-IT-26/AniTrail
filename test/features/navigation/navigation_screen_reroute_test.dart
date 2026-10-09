import 'dart:async';

import 'package:anitrail/features/map/models/anime_spot.dart';
import 'package:anitrail/features/navigation/controllers/navigation_route_controller.dart';
import 'package:anitrail/features/navigation/models/navigation_route.dart';
import 'package:anitrail/features/navigation/screens/navigation_screen_mobile.dart';
import 'package:anitrail/features/navigation/widgets/direction_arrow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// The map plugin exposes its test platform through its interface package.
// ignore: depend_on_referenced_packages
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

const start = LatLng(35, 139);
const away = LatLng(35, 139.00045);

Position position(LatLng point) => Position(
  latitude: point.latitude,
  longitude: point.longitude,
  timestamp: DateTime(2026),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

class TestLocation extends GeolocatorPlatform {
  final updates = StreamController<Position>.broadcast();
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => position(start);
  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      updates.stream;
}

class TestMap extends GoogleMapsFlutterPlatform {
  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapConfiguration mapConfiguration = const MapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) => const SizedBox.expand();
}

void main() {
  for (final directionMode in [false, true]) {
    testWidgets(
      '${directionMode ? 'direction' : 'map'} mode refreshes from streamed positions and retries failures',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final oldLocation = GeolocatorPlatform.instance;
        final oldMap = GoogleMapsFlutterPlatform.instance;
        final location = TestLocation();
        GeolocatorPlatform.instance = location;
        GoogleMapsFlutterPlatform.instance = TestMap();
        addTearDown(() async {
          GeolocatorPlatform.instance = oldLocation;
          GoogleMapsFlutterPlatform.instance = oldMap;
          await location.updates.close();
        });
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('anitrail/device_heading'),
          (_) async => null,
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            const MethodChannel('anitrail/device_heading'),
            null,
          ),
        );
        final destination = LatLng(directionMode ? 35.0007 : 35.01, 139);
        var now = DateTime(2026);
        final requests = <Completer<NavigationRoute>>[];
        final origins = <LatLng>[];
        final controller = NavigationRouteController(
          destination: destination,
          now: () => now,
          fetchRoute: ({required origin, required destination}) {
            origins.add(origin);
            final request = Completer<NavigationRoute>();
            requests.add(request);
            return request.future;
          },
        );
        await tester.pumpWidget(
          MaterialApp(
            home: NavigationScreen(
              spot: Spot(
                spotId: 'test',
                name: 'テスト聖地',
                latitude: destination.latitude,
                longitude: destination.longitude,
              ),
              cardId: 'test',
              origin: start,
              routeController: controller,
            ),
          ),
        );
        await tester.pump();
        requests.first.complete(
          NavigationRoute(
            points: [start, destination],
            distanceMeters: 1000,
            durationSeconds: 800,
          ),
        );
        await tester.pump();
        await tester.pump();
        now = now.add(const Duration(seconds: 15));
        location.updates.add(position(away));
        await tester.pump();
        location.updates.add(position(away));
        await tester.pump();
        expect(origins, [start, away]);
        expect(find.text('徒歩ルートを更新中…'), findsWidgets);
        if (directionMode) {
          expect(
            tester
                .widget<DirectionArrow>(find.byType(DirectionArrow))
                .routeBearingDegrees,
            isNull,
          );
        }
        requests.last.completeError(Exception('offline'));
        await tester.pump();
        expect(find.text('再試行'), findsOneWidget);
        await tester.tap(find.text('再試行'));
        await tester.pump();
        expect(origins, hasLength(3));
        final newPoints = [away, LatLng(away.latitude, 139.0002), destination];
        requests.last.complete(
          NavigationRoute(
            points: newPoints,
            distanceMeters: 900,
            durationSeconds: 720,
          ),
        );
        await tester.pump();
        expect(find.text('徒歩ルートを更新中…'), findsNothing);
        expect(find.text('再試行'), findsNothing);
        if (directionMode) {
          expect(
            tester
                .widget<DirectionArrow>(find.byType(DirectionArrow))
                .routeBearingDegrees,
            closeTo(270, 1),
          );
        } else {
          expect(
            tester
                .widget<GoogleMap>(find.byType(GoogleMap))
                .polylines
                .single
                .points,
            newPoints,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      },
    );
  }
}
