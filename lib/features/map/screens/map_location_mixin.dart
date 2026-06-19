import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/anime_spot.dart';

/// 位置情報トラッキングと地図カメラ操作を担当するミックスイン。
mixin MapLocationMixin<T extends StatefulWidget> on State<T> {
  GoogleMapController? mapController;
  double currentZoom = 15.0;
  double baseZoom = 15.0;
  LatLng currentLatLng = const LatLng(34.702, 135.496);
  bool locationGranted = false;
  bool hasFix = false;
  Spot? pinnedSpot;

  StreamSubscription<Position>? _positionSubscription;

  static const CameraPosition initialPosition = CameraPosition(
    target: LatLng(34.702, 135.496),
    zoom: 15,
  );

  Future<void> startLocationTracking() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (!mounted) return;
      showLocationDialog('位置情報サービスが無効です', '端末の設定で位置情報をオンにしてください。');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      showLocationDialog(
        '位置情報の許可が必要です',
        '設定アプリから位置情報のアクセスを許可してください。',
        openSettings: true,
      );
      return;
    }
    if (permission == LocationPermission.denied) return;

    if (mounted) setState(() => locationGranted = true);

    try {
      final position = await Geolocator.getCurrentPosition();
      onPosition(position);
    } catch (_) {}

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen(onPosition);
  }

  void onPosition(Position position) {
    if (!mounted) return;
    currentLatLng = LatLng(position.latitude, position.longitude);
    hasFix = true;
    // ピン表示中は現在地に追従しない
    if (pinnedSpot != null) return;
    recenterCamera(animate: true);
  }

  void onScaleStart(ScaleStartDetails d) {
    if (d.pointerCount >= 2) baseZoom = currentZoom;
  }

  void onScaleUpdate(ScaleUpdateDetails d) {
    if (d.pointerCount < 2) return;
    final zoom = (baseZoom + log(d.scale) / log(2)).clamp(3.0, 21.0);
    currentZoom = zoom;
    recenterCamera();
  }

  void pinSpot(Spot spot) {
    setState(() => pinnedSpot = spot);
    recenterCamera(animate: true);
  }

  void clearPin() {
    setState(() => pinnedSpot = null);
    recenterCamera(animate: true);
  }

  /// 追従対象（ピン優先、なければ現在地）。null なら追従対象なし。
  LatLng? get focusTarget {
    final spot = pinnedSpot;
    if (spot?.latitude != null && spot?.longitude != null) {
      return LatLng(spot!.latitude!, spot.longitude!);
    }
    if (hasFix) return currentLatLng;
    return null;
  }

  /// 追従対象をカメラ中央に合わせる。
  /// MapScreen 側で「見える領域の中央」に来るようオーバーライドする。
  void recenterCamera({bool animate = false}) {
    final target = focusTarget;
    if (target == null) return;
    final update = CameraUpdate.newLatLngZoom(target, currentZoom);
    if (animate) {
      mapController?.animateCamera(update);
    } else {
      mapController?.moveCamera(update);
    }
  }

  void showLocationDialog(String title, String message, {bool openSettings = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          if (openSettings)
            TextButton(
              onPressed: () { Navigator.pop(ctx); Geolocator.openAppSettings(); },
              child: const Text('設定を開く'),
            ),
        ],
      ),
    );
  }

  void disposeLocation() {
    _positionSubscription?.cancel();
    mapController?.dispose();
  }
}
