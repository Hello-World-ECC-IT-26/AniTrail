import 'dart:async';
import 'package:anitrail/features/map/models/anime_spot.dart';
import 'package:anitrail/features/map/models/tour_plan.dart';
import 'package:anitrail/features/map/services/tour_controller.dart';
import 'package:anitrail/features/map/services/tour_plan_store.dart';
import 'package:anitrail/features/navigation/models/navigation_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const a = Spot(spotId: 'a', name: 'A', latitude: 35, longitude: 139);
const b = Spot(spotId: 'b', name: 'B', latitude: 36, longitude: 139);
const missing = Spot(spotId: 'missing', name: 'M');
const card = StampCard(
  cardId: 'c',
  title: 'C',
  spotCount: 3,
  spots: [a, b, missing],
);
const route = NavigationRoute(
  points: [LatLng(35, 139), LatLng(36, 139)],
  distanceMeters: 100,
  durationSeconds: 80,
);

class MemoryStore implements TourPlanStore {
  TourPlan plan = TourPlan([]);
  bool fail = false;
  Completer<void>? pending;
  @override
  Future<TourPlan> load(String userId, String cardId) async => plan;
  @override
  Future<void> save(String userId, String cardId, TourPlan next) async {
    if (fail) throw StateError('disk unavailable');
    await pending?.future;
    plan = next;
  }
}

Future<TourController> controller({
  MemoryStore? store,
  TourRouteLoader? loader,
}) async {
  final result = TourController(
    userId: 'u',
    store: store ?? MemoryStore(),
    loadRoute:
        loader ?? ({required origin, required destination}) async => route,
  );
  await result.selectCard(card);
  return result;
}

void main() {
  test('現在地なしでは開始できず、座標なしは選択できない', () async {
    final c = await controller();
    addTearDown(c.dispose);
    c.beginEditing();
    expect(c.active, isFalse);
    c.setCurrentLocation(const LatLng(35, 139));
    c.beginEditing();
    c.toggle(missing);
    expect(c.spots, isEmpty);
    c.toggle(a);
    c.toggle(b);
    c.toggle(a);
    expect(c.spots, [b]);
  });
  test('並べ替えと取消で保存済み順番を変更しない', () async {
    final store = MemoryStore()..plan = TourPlan(['a', 'b']);
    final c = await controller(store: store);
    addTearDown(c.dispose);
    c.setCurrentLocation(const LatLng(35, 139));
    c.beginEditing();
    c.reorder(0, 2);
    expect(c.spots, [b, a]);
    expect(c.savedSpots, [a, b]);
    c.cancelEditing();
    expect(c.spots, [a, b]);
    c.beginEditing();
    c.reorder(0, 2);
    expect(await c.save(), isTrue);
    expect(store.plan.spotIds, ['b', 'a']);
  });
  test('保存失敗は下書きを保持し、再試行できる', () async {
    final store = MemoryStore()..fail = true;
    final c = await controller(store: store);
    addTearDown(c.dispose);
    c.setCurrentLocation(const LatLng(35, 139));
    c.beginEditing();
    c.toggle(a);
    expect(await c.save(), isFalse);
    expect(c.editing, isTrue);
    expect(c.savedSpots, isEmpty);
    expect(c.error, isNotNull);
    store.fail = false;
    expect(await c.save(), isTrue);
  });
  test('保存中の編集と取消を防ぎ、ログアウト後の完了を反映しない', () async {
    final store = MemoryStore()..pending = Completer<void>();
    final c = await controller(store: store);
    addTearDown(c.dispose);
    c.setCurrentLocation(const LatLng(35, 139));
    c.beginEditing();
    c.toggle(a);
    final saved = c.save();
    c.toggle(b);
    c.cancelEditing();
    expect(c.spots, [a]);
    c.setUser(null);
    store.pending!.complete();
    expect(await saved, isFalse);
    expect(c.savedSpots, isEmpty);
  });
  test('古い経路の完了を破棄し、最新の選択だけに反映する', () async {
    final calls = <Completer<NavigationRoute>>[];
    final c = await controller(
      loader: ({required origin, required destination}) {
        final completer = Completer<NavigationRoute>();
        calls.add(completer);
        return completer.future;
      },
    );
    addTearDown(c.dispose);
    c.setCurrentLocation(const LatLng(35, 139));
    c.beginEditing();
    c.toggle(a);
    c.toggle(a);
    c.toggle(b);
    calls.last.complete(route);
    await Future<void>.delayed(Duration.zero);
    expect(c.legs, [route]);
    calls.first.completeError(StateError('stale failure'));
    await Future<void>.delayed(Duration.zero);
    expect(c.routeError, isNull);
    expect(c.spots, [b]);
  });
  test('マーカー読み込み失敗を通知し、経路再取得でも維持する', () async {
    final c = await controller();
    addTearDown(c.dispose);
    c.setCurrentLocation(const LatLng(34, 139));
    c.beginEditing();
    c.toggle(a);
    var notifications = 0;
    c.addListener(() => notifications++);
    c.setMarkerLoadingError('marker failure');
    expect(notifications, 1);
    expect(c.markerError, 'marker failure');
    await c.refreshRoutes();
    expect(c.markerError, 'marker failure');
    expect(c.routeError, isNull);
    final beforeRecovery = notifications;
    c.setMarkerLoadingError(null);
    expect(c.markerError, isNull);
    expect(notifications, beforeRecovery + 1);
  });
  test('経路失敗を代替せず再試行し、現在地から順番に区間を取得する', () async {
    var fail = true;
    final origins = <LatLng>[];
    final c = await controller(
      loader: ({required origin, required destination}) async {
        origins.add(origin);
        if (fail) throw StateError('network');
        return route;
      },
    );
    addTearDown(c.dispose);
    c.setCurrentLocation(const LatLng(34, 139));
    c.beginEditing();
    c.toggle(a);
    c.toggle(b);
    await Future<void>.delayed(Duration.zero);
    expect(c.routeError, isNotNull);
    expect(c.legs, isEmpty);
    fail = false;
    origins.clear();
    await c.refreshRoutes();
    expect(origins, [const LatLng(34, 139), const LatLng(35, 139)]);
    expect(c.legs, hasLength(2));
  });
}
