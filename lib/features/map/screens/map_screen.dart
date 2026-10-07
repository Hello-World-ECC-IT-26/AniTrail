import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/tour_controller.dart';
import '../widgets/tour_map_assets.dart';
import '../widgets/map_tour_panel.dart';

import '../models/anime_spot.dart';
import '../models/tour_plan.dart';
import '../widgets/map_results_sheet.dart';
import '../widgets/map_search_bar.dart';
import '../widgets/map_search_panel.dart';
import '../widgets/map_shiori_sheet.dart';
import '../widgets/map_tutorial.dart';
import '../../spot/screens/spot_detail.dart';
import 'map_location_mixin.dart';
import 'map_search_mixin.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.initialShiori});

  final StampCard? initialShiori;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with MapLocationMixin<MapScreen>, MapSearchMixin<MapScreen> {
  // 現在のシート占有率（0.0〜1.0）。MapResultsSheet の initialChildSize と揃える。
  double _sheetSize = 0.55;

  // しおり一覧シートの表示状態
  bool _shioriVisible = false;
  bool _shioriDetailVisible = false;
  bool _tutorialRequested = false;
  late final TourController _tour;
  final TourMapAssets _tourAssets = TourMapAssets();
  StreamSubscription<AuthState>? _authSubscription;
  bool _loadingTourAssets = false;

  void _onTourChanged() {
    if (!mounted) return;
    setState(() {});
    if (_tour.active &&
        !_loadingTourAssets &&
        (_tourAssets.start == null ||
            _tourAssets.numbered.length < _tour.spots.length)) {
      _loadTourAssets();
    }
  }

  Future<void> _loadTourAssets() async {
    _loadingTourAssets = true;
    try {
      await _tourAssets.load(_tour.spots.length);
    } catch (_) {
      if (mounted) {
        _tour.routeError = '地図の巡回マーカーを読み込めませんでした';
      }
    } finally {
      _loadingTourAssets = false;
    }
    if (mounted) setState(() {});
  }

  void _fitTour() {
    if (!_tour.active) return;
    final origin = _tour.routeOrigin;
    fitSpotsBounds([
      if (origin != null)
        Spot(
          spotId: 'tour_origin',
          name: '現在地',
          latitude: origin.latitude,
          longitude: origin.longitude,
        ),
      ..._tour.spots,
    ]);
  }

  @override
  double get currentLat => currentLatLng.latitude;

  @override
  double get currentLng => currentLatLng.longitude;

  /// 追従対象を「見える領域（検索バー下〜シート上端）」の中央に合わせる。
  @override
  void recenterCamera({bool animate = false}) {
    final target = focusTarget;
    if (target == null || mapController == null) return;

    final screenH = MediaQuery.of(context).size.height;
    final safeTop = MediaQuery.of(context).padding.top;
    final topPx = safeTop + 80.0; // 検索バー下端
    final bottomPx = resultsVisible
        ? screenH *
              (1 - _sheetSize) // シート上端
        : screenH; // シートなしなら画面下端
    final visibleCenterY = (topPx + bottomPx) / 2;
    final screenCenterY = screenH / 2;
    final offsetPx = visibleCenterY - screenCenterY;

    // ズームレベルと緯度から 1px あたりの緯度を計算
    final metersPerPx =
        156543.03392 *
        math.cos(target.latitude * math.pi / 180) /
        math.pow(2, currentZoom);
    final latPerPx = metersPerPx / 111320; // 緯度1度 ≒ 111320m
    final latOffset = offsetPx * latPerPx;

    final dest = LatLng(target.latitude + latOffset, target.longitude);
    final update = CameraUpdate.newLatLngZoom(dest, currentZoom);
    if (animate) {
      mapController!.animateCamera(update);
    } else {
      mapController!.moveCamera(update);
    }
  }

  @override
  void initState() {
    super.initState();
    _tour = TourController(
      userId: Supabase.instance.client.auth.currentUser?.id,
    );
    _tour.addListener(_onTourChanged);
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      event,
    ) {
      _tour.setUser(event.session?.user.id);
    });
    if (widget.initialShiori != null) {
      _shioriVisible = true;
      _shioriDetailVisible = true;
    }
    loadHistory();
    startLocationTracking();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorial();
    });
  }

  Future<void> _showTutorial() async {
    if (_tutorialRequested || !mounted) return;
    _tutorialRequested = true;
    await showMapTutorialIfNeeded(context);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _tour.removeListener(_onTourChanged);
    _tour.dispose();
    disposeLocation();
    disposeSearch();
    super.dispose();
  }

  @override
  void onPosition(Position position) {
    if (!mounted) return;
    super.onPosition(position);
    _tour.setCurrentLocation(hasFix ? currentLatLng : null);
  }

  void _onSpotTap(Spot spot) {
    pinSpot(spot);
  }

  void _openShioriSpotDetail(Spot spot) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SpotDetailScreen(
          spot: spot,
          animeTitle: spot.animeTitle ?? '',
          keyVisualUrl: spot.keyVisualUrl,
          showShioriActions: false,
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    if (_tour.active) {
      final origin = _tour.routeOrigin;
      if (origin != null && _tourAssets.start != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('tour_start'),
            position: origin,
            icon: _tourAssets.start!,
            infoWindow: const InfoWindow(title: 'スタート地点（現在地）'),
          ),
        );
      }
      for (final spot in _tour.card?.spots ?? <Spot>[]) {
        if (!canTourSpot(spot)) continue;
        final index = _tour.spots.indexWhere((s) => s.spotId == spot.spotId);
        if (index >= 0 && _tourAssets.numbered[index] == null) continue;
        markers.add(
          Marker(
            markerId: MarkerId('tour_${spot.spotId}'),
            position: LatLng(spot.latitude!, spot.longitude!),
            icon: index >= 0
                ? _tourAssets.numbered[index]!
                : BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: index < 0 ? spot.name : '${index + 1}. ${spot.name}',
            ),
            onTap: _tour.editing ? () => _tour.toggle(spot) : null,
          ),
        );
      }
      return markers;
    }
    // 単一ピン（検索結果の聖地詳細）
    final single = pinnedSpot;
    if (single?.latitude != null && single?.longitude != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pinned'),
          position: LatLng(single!.latitude!, single.longitude!),
        ),
      );
    }
    // 複数ピン（しおりの聖地）
    for (final spot in pinnedSpots) {
      if (spot.latitude == null || spot.longitude == null) continue;
      markers.add(
        Marker(
          markerId: MarkerId('shiori_${spot.spotId}'),
          position: LatLng(spot.latitude!, spot.longitude!),
          infoWindow: InfoWindow(title: spot.name),
          onTap: () => _openShioriSpotDetail(spot),
        ),
      );
    }
    return markers;
  }

  void _onCloseSearch() {
    closeSearch(); // resultsVisible = false に
    clearPin(); // ピン解除 → 現在地へ再センタリング（シートなしの中央）
  }

  void _openMapSearch() {
    _tour.hide();
    clearSpotPins();
    setState(() {
      _shioriVisible = false;
      _shioriDetailVisible = false;
    });
    openSearch();
  }

  void _toggleShiori() {
    final visible = !_shioriVisible;
    if (!visible) {
      _tour.clear();
      clearSpotPins();
    }
    setState(() {
      _shioriVisible = visible;
      if (!visible) _shioriDetailVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final overlayActive = searchVisible || resultsVisible;
    final mapGesturesEnabled =
        _tour.active || (_shioriVisible && _shioriDetailVisible);

    return PopScope(
      canPop: !_tour.active,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _tour.saving) return;
        if (_tour.editing) {
          _tour.cancelEditing();
        } else {
          _tour.hide();
        }
      },
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
        child: GestureDetector(
          onScaleStart: overlayActive || mapGesturesEnabled
              ? null
              : onScaleStart,
          onScaleUpdate: overlayActive || mapGesturesEnabled
              ? null
              : onScaleUpdate,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: MapLocationMixin.initialPosition,
                padding: _tour.active
                    ? EdgeInsets.only(
                        top: MediaQuery.paddingOf(context).top + 130,
                        bottom: MediaQuery.sizeOf(context).height * _sheetSize,
                      )
                    : EdgeInsets.zero,
                polylines: {
                  for (var i = 0; i < _tour.legs.length; i++)
                    Polyline(
                      polylineId: PolylineId('tour_leg_$i'),
                      points: _tour.legs[i].points,
                      width: 5,
                      color: tourColor(i),
                    ),
                },
                myLocationEnabled: locationGranted,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                scrollGesturesEnabled: mapGesturesEnabled,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                zoomGesturesEnabled: mapGesturesEnabled,
                markers: _buildMarkers(),
                onCameraMove: (position) => currentZoom = position.zoom,
                onMapCreated: (controller) {
                  mapController = controller;
                  if (hasFix) {
                    mapController?.moveCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: currentLatLng,
                          zoom: currentZoom,
                        ),
                      ),
                    );
                  }
                },
              ),

              if (!searchVisible && !_tour.active)
                MapSearchBar(
                  query: displayQuery,
                  onTap: _openMapSearch,
                  onShioriTap: _toggleShiori,
                  showShiori: !resultsVisible,
                  onBack: resultsVisible ? _onCloseSearch : null,
                ),

              if (_shioriVisible && !searchVisible && !resultsVisible)
                MapShioriSheet(
                  initialCard: widget.initialShiori,
                  tour: _tour,
                  onSheetSizeChanged: (size) {
                    if ((_sheetSize - size).abs() > 0.01) {
                      setState(() => _sheetSize = size);
                    }
                  },
                  currentLocation: hasFix ? currentLatLng : null,
                  onClose: () {
                    clearSpotPins();
                    setState(() {
                      _shioriVisible = false;
                      _shioriDetailVisible = false;
                    });
                  },
                  onShowSpots: showSpotPins,
                  onClearSpots: clearSpotPins,
                  onDetailVisibilityChanged: (visible) {
                    setState(() => _shioriDetailVisible = visible);
                  },
                ),

              if (_tour.active) TourEndpoints(tour: _tour),
              if (_tour.active)
                Positioned(
                  right: 16,
                  top: MediaQuery.paddingOf(context).top + 146,
                  child: IconButton.filledTonal(
                    tooltip: '巡回ルート全体を表示',
                    onPressed: _fitTour,
                    icon: const Icon(Icons.fit_screen),
                  ),
                ),
              if (searchVisible)
                MapSearchPanel(
                  controller: searchController,
                  focusNode: searchFocus,
                  history: history,
                  onBack: _onCloseSearch,
                  onSubmit: submitSearch,
                  onClear: clearSearchInput,
                  onSelectHistory: selectHistory,
                  onDeleteHistory: (item) {
                    setState(() => history.remove(item));
                    saveHistory();
                  },
                ),

              if (resultsVisible)
                MapResultsSheet(
                  currentLocation: hasFix ? currentLatLng : null,
                  results: results,
                  loading: loading,
                  spotsLoading: spotsLoading,
                  error: searchError,
                  selectedAnime: selectedAnime,
                  filterIndex: filterIndex,
                  sortIndex: sortIndex,
                  onSelectAnime: selectAnime,
                  onBack: () => setState(() => selectedAnime = null),
                  onFilterChange: (i) => setState(() => filterIndex = i),
                  onSortChange: (i) => setState(() => sortIndex = i),
                  onSpotTap: _onSpotTap,
                  onDetailClose: clearPin,
                  onArrivalRecorded: () async {
                    final anime = selectedAnime;
                    if (anime == null) return;
                    anime.spots = [];
                    await selectAnime(anime);
                  },
                  onSheetSizeChanged: (size) {
                    _sheetSize = size;
                    recenterCamera(); // ドラッグ追従は即時（moveCamera）
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
