import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/anime_spot.dart';
import '../widgets/map_results_sheet.dart';
import '../widgets/map_search_bar.dart';
import '../widgets/map_search_panel.dart';
import 'map_location_mixin.dart';
import 'map_search_mixin.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with MapLocationMixin<MapScreen>, MapSearchMixin<MapScreen> {
  // 現在のシート占有率（0.0〜1.0）。MapResultsSheet の initialChildSize と揃える。
  double _sheetSize = 0.55;

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
    final topPx = safeTop + 80.0;                  // 検索バー下端
    final bottomPx = resultsVisible
        ? screenH * (1 - _sheetSize)               // シート上端
        : screenH;                                 // シートなしなら画面下端
    final visibleCenterY = (topPx + bottomPx) / 2;
    final screenCenterY = screenH / 2;
    final offsetPx = visibleCenterY - screenCenterY;

    // ズームレベルと緯度から 1px あたりの緯度を計算
    final metersPerPx = 156543.03392 *
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
    loadHistory();
    startLocationTracking();
  }

  @override
  void dispose() {
    disposeLocation();
    disposeSearch();
    super.dispose();
  }

  void _onSpotTap(Spot spot) {
    pinSpot(spot);
  }

  void _onCloseSearch() {
    closeSearch();   // resultsVisible = false に
    clearPin();      // ピン解除 → 現在地へ再センタリング（シートなしの中央）
  }

  @override
  Widget build(BuildContext context) {
    final overlayActive = searchVisible || resultsVisible;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
      child: GestureDetector(
        onScaleStart: overlayActive ? null : onScaleStart,
        onScaleUpdate: overlayActive ? null : onScaleUpdate,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: MapLocationMixin.initialPosition,
              // センタリングは recenterCamera で手動制御するため padding は使わない
              padding: EdgeInsets.zero,
              myLocationEnabled: locationGranted,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              scrollGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              zoomGesturesEnabled: false,
              markers: pinnedSpot != null && pinnedSpot!.latitude != null
                  ? {
                      Marker(
                        markerId: const MarkerId('pinned'),
                        position: LatLng(pinnedSpot!.latitude!, pinnedSpot!.longitude!),
                      ),
                    }
                  : {},
              onMapCreated: (controller) {
                mapController = controller;
                if (hasFix) {
                  mapController?.moveCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(target: currentLatLng, zoom: currentZoom),
                    ),
                  );
                }
              },
            ),

            if (!searchVisible)
              MapSearchBar(
                query: displayQuery,
                onTap: openSearch,
                onShioriTap: () {},
                showShiori: !resultsVisible,
                onBack: resultsVisible ? _onCloseSearch : null,
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
                onSheetSizeChanged: (size) {
                  _sheetSize = size;
                  recenterCamera(); // ドラッグ追従は即時（moveCamera）
                },
              ),
          ],
        ),
      ),
    );
  }
}
