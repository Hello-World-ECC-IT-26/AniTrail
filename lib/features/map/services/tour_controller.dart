import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../navigation/models/navigation_route.dart';
import '../../navigation/services/navigation_route_service.dart';
import '../models/anime_spot.dart';
import '../models/tour_plan.dart';
import 'tour_plan_store.dart';

typedef TourRouteLoader =
    Future<NavigationRoute> Function({
      required LatLng origin,
      required LatLng destination,
    });

/// Shared by the map markers and the shiori sheet. Drafts never overwrite saves.
class TourController extends ChangeNotifier {
  TourController({
    required String? userId,
    TourPlanStore? store,
    TourRouteLoader? loadRoute,
  }) : _userId = userId,
       _store = store ?? LocalTourPlanStore(),
       _loadRoute = loadRoute ?? NavigationRouteService().fetchWalkingRoute;

  String? _userId;
  final TourPlanStore _store;
  final TourRouteLoader _loadRoute;
  StampCard? card;
  LatLng? currentLocation;
  LatLng? routeOrigin;
  List<Spot> savedSpots = [];
  List<Spot> draftSpots = [];
  List<NavigationRoute> legs = [];
  bool active = false;
  bool editing = false;
  bool loading = false;
  bool saving = false;
  bool routing = false;
  String? error;
  String? routeError;
  String? _markerError;
  String? get markerError => _markerError;

  void setMarkerLoadingError(String? message) {
    if (_disposed || _markerError == message) return;
    _markerError = message;
    notifyListeners();
  }

  int _revision = 0;
  int _routeRevision = 0;
  bool _disposed = false;
  List<Spot> get spots => editing ? draftSpots : savedSpots;
  bool get canStart =>
      _userId != null &&
      currentLocation != null &&
      !loading &&
      !saving &&
      (card?.spots.any(canTourSpot) ?? false);

  void setUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    clear();
  }

  void setCurrentLocation(LatLng? location) {
    if (currentLocation == location) return;
    currentLocation = location;
    if (active && routeOrigin == null && location != null) {
      routeOrigin = location;
      refreshRoutes();
    }
    notifyListeners();
  }

  Future<void> selectCard(StampCard next, {bool force = false}) async {
    if (!force && card?.cardId == next.cardId && !loading && error == null) {
      card = next;
      savedSpots = TourPlan(
        savedSpots.map((s) => s.spotId),
      ).resolve(next.spots);
      draftSpots = TourPlan(
        draftSpots.map((s) => s.spotId),
      ).resolve(next.spots);
      if (active) refreshRoutes();
      notifyListeners();
      return;
    }
    clear(notify: false);
    card = next;
    final userId = _userId;
    if (userId == null) {
      error = '巡る順番を保存するにはログインしてください';
      notifyListeners();
      return;
    }
    final revision = ++_revision;
    loading = true;
    notifyListeners();
    try {
      final plan = await _store.load(userId, next.cardId);
      if (_disposed || revision != _revision) return;
      savedSpots = plan.resolve(next.spots);
    } catch (_) {
      if (_disposed || revision != _revision) return;
      error = '巡る順番を読み込めませんでした。再試行してください。';
    }
    if (_disposed || revision != _revision) return;
    loading = false;
    notifyListeners();
  }

  void beginEditing() {
    if (!canStart || card == null) return;
    draftSpots = List.of(savedSpots);
    active = true;
    editing = true;
    error = null;
    routeOrigin = currentLocation;
    refreshRoutes();
    notifyListeners();
  }

  void showSaved() {
    if (savedSpots.isEmpty) return;
    active = true;
    editing = false;
    routeOrigin = currentLocation;
    refreshRoutes();
    notifyListeners();
  }

  void toggle(Spot spot) {
    if (!editing ||
        saving ||
        !canTourSpot(spot) ||
        !(card?.spots.any((s) => s.spotId == spot.spotId) ?? false)) {
      return;
    }
    final index = draftSpots.indexWhere((s) => s.spotId == spot.spotId);
    draftSpots = List.of(draftSpots);
    if (index < 0) {
      draftSpots.add(spot);
    } else {
      draftSpots.removeAt(index);
    }
    refreshRoutes();
    notifyListeners();
  }

  void reorder(int oldIndex, int newIndex) {
    if (!editing || saving) return;
    if (newIndex > oldIndex) newIndex--;
    draftSpots = List.of(draftSpots);
    final spot = draftSpots.removeAt(oldIndex);
    draftSpots.insert(newIndex, spot);
    refreshRoutes();
    notifyListeners();
  }

  Future<bool> save() async {
    final userId = _userId;
    final selected = card;
    if (!editing ||
        saving ||
        draftSpots.isEmpty ||
        userId == null ||
        selected == null) {
      return false;
    }
    final revision = _revision;
    final committed = List<Spot>.of(draftSpots);
    saving = true;
    error = null;
    notifyListeners();
    try {
      await _store.save(
        userId,
        selected.cardId,
        TourPlan(committed.map((s) => s.spotId)),
      );
      if (_disposed || revision != _revision) return false;
      savedSpots = committed;
      editing = false;
      saving = false;
      notifyListeners();
      return true;
    } catch (_) {
      if (_disposed || revision != _revision) return false;
      saving = false;
      error = '巡る順番を保存できませんでした。再試行してください。';
      notifyListeners();
      return false;
    }
  }

  void cancelEditing() {
    if (saving) return;
    draftSpots = [];
    editing = false;
    active = savedSpots.isNotEmpty;
    error = null;
    refreshRoutes();
    notifyListeners();
  }

  void hide() {
    if (saving) return;
    active = false;
    editing = false;
    draftSpots = [];
    legs = [];
    routing = false;
    routeError = null;
    _routeRevision++;
    notifyListeners();
  }

  Future<void> refreshRoutes() async {
    final revision = ++_routeRevision;
    final origin = routeOrigin;
    final ordered = List<Spot>.of(spots);
    legs = [];
    routeError = null;
    routing = active && origin != null && ordered.isNotEmpty;
    notifyListeners();
    if (!routing) return;
    try {
      final result = <NavigationRoute>[];
      var from = origin!;
      for (final spot in ordered) {
        if (_disposed || revision != _routeRevision) return;
        final to = LatLng(spot.latitude!, spot.longitude!);
        result.add(await _loadRoute(origin: from, destination: to));
        from = to;
      }
      if (_disposed || revision != _routeRevision) return;
      legs = result;
    } catch (_) {
      if (_disposed || revision != _routeRevision) return;
      routeError = '徒歩ルートを取得できませんでした';
    }
    if (_disposed || revision != _routeRevision) return;
    routing = false;
    notifyListeners();
  }

  void clear({bool notify = true}) {
    _revision++;
    _routeRevision++;
    card = null;
    savedSpots = [];
    draftSpots = [];
    legs = [];
    active = editing = loading = saving = routing = false;
    error = routeError = null;
    routeOrigin = null;
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    _routeRevision++;
    super.dispose();
  }
}
