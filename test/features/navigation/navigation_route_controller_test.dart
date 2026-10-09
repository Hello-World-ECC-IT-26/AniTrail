import 'dart:async';

import 'package:anitrail/features/navigation/controllers/navigation_route_controller.dart';
import 'package:anitrail/features/navigation/models/navigation_route.dart';
import 'package:anitrail/features/navigation/models/navigation_route_distance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const start = LatLng(35, 139);
const end = LatLng(35.01, 139);
const away = LatLng(35.005, 139.001);
const route = NavigationRoute(
  points: [start, end],
  distanceMeters: 1113,
  durationSeconds: 900,
);

void main() {
  test(
    'distance uses segment interiors, corners, duplicates and empty routes',
    () {
      expect(
        distanceToWalkingRoute(const LatLng(35.005, 139), route.points),
        closeTo(0, .01),
      );
      expect(distanceToWalkingRoute(away, route.points), greaterThan(30));
      expect(
        distanceToWalkingRoute(end, [
          start,
          end,
          end,
          const LatLng(35.01, 139.01),
        ]),
        0,
      );
      expect(distanceToWalkingRoute(start, [end, end]), greaterThan(1000));
      expect(distanceToWalkingRoute(start, []), isNull);
    },
  );

  late NavigationRouteController controller;
  late DateTime now;
  late List<LatLng> origins;
  late List<Completer<NavigationRoute>> requests;
  setUp(() {
    now = DateTime(2026);
    origins = [];
    requests = [];
    controller = NavigationRouteController(
      destination: end,
      now: () => now,
      fetchRoute: ({required origin, required destination}) {
        origins.add(origin);
        final request = Completer<NavigationRoute>();
        requests.add(request);
        return request.future;
      },
    );
    controller.currentLocation = start;
  });
  tearDown(() => controller.dispose());

  Future<void> initialize() async {
    final pending = controller.requestRoute();
    requests.last.complete(route);
    await pending;
  }

  void position(LatLng point, {double accuracy = 5, bool arrived = false}) =>
      controller.updatePosition(point, accuracy: accuracy, arrived: arrived);
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test(
    'normal travel and poor accuracy do not reroute; departure needs two consecutive fixes',
    () async {
      await initialize();
      now = now.add(const Duration(seconds: 15));
      position(const LatLng(35.005, 139));
      position(away);
      position(away, accuracy: 31);
      position(away);
      expect(origins, hasLength(1));
      position(away);
      expect(origins, hasLength(2));
      expect(controller.guidanceUnavailable, isTrue);
      expect(controller.updating, isTrue);
      requests.last.complete(route);
      await settle();
    },
  );

  test(
    'requests serialize and retain the latest location during fetching',
    () async {
      final pending = controller.requestRoute();
      await controller.requestRoute();
      position(away);
      expect(origins, [start]);
      requests.last.complete(route);
      await pending;
      expect(controller.currentLocation, away);
      expect(controller.route, same(route));
    },
  );

  test('returning to the route resets departure confirmation', () async {
    await initialize();
    now = now.add(const Duration(seconds: 15));
    position(away);
    position(start);
    position(away);
    expect(origins, hasLength(1));
  });

  test(
    'failed reroute shows error, retries after cooldown and recovers',
    () async {
      await initialize();
      position(away);
      position(away);
      expect(origins, hasLength(1));
      now = now.add(const Duration(seconds: 15));
      position(away);
      requests.last.completeError(Exception('offline'));
      await settle();
      expect(controller.error, contains('offline'));
      expect(controller.guidanceUnavailable, isTrue);
      position(away);
      expect(origins, hasLength(2));
      now = now.add(const Duration(seconds: 15));
      position(away);
      const updated = NavigationRoute(
        points: [away, end],
        distanceMeters: 600,
        durationSeconds: 480,
      );
      requests.last.complete(updated);
      await settle();
      expect(controller.route, same(updated));
      expect(controller.guidanceUnavailable, isFalse);
      expect(controller.error, isNull);
    },
  );

  test('manual retry bypasses cooldown but never overlaps', () async {
    await initialize();
    final pending = controller.requestRoute();
    await controller.requestRoute();
    expect(origins, hasLength(2));
    requests.last.complete(route);
    await pending;
  });

  test('arrival prevents late results and future requests', () async {
    final pending = controller.requestRoute();
    position(end, arrived: true);
    requests.last.complete(route);
    await pending;
    expect(controller.route, isNull);
    await controller.requestRoute();
    expect(origins, hasLength(1));
  });

  test('disposal prevents late result notification', () async {
    final local = NavigationRouteController(
      destination: end,
      fetchRoute: ({required origin, required destination}) =>
          requests.first.future,
    );
    requests.add(Completer<NavigationRoute>());
    local.currentLocation = start;
    var notifications = 0;
    local.addListener(() => notifications++);
    final pending = local.requestRoute();
    local.dispose();
    requests.first.complete(route);
    await pending;
    expect(local.route, isNull);
    expect(notifications, 1);
  });

  test(
    'initial location starts acquisition even before a precise GPS fix',
    () async {
      controller.currentLocation = null;
      position(start, accuracy: 50);
      expect(origins, [start]);
      requests.last.complete(route);
      await settle();
      expect(controller.route, same(route));
    },
  );

  test('timeout clears loading and allows retry', () async {
    final local = NavigationRouteController(
      destination: end,
      requestTimeout: const Duration(milliseconds: 1),
      fetchRoute: ({required origin, required destination}) =>
          Completer<NavigationRoute>().future,
    );
    local.currentLocation = start;
    await local.requestRoute();
    expect(local.error, contains('TimeoutException'));
    expect(local.loading, isFalse);
    local.dispose();
  });
}
