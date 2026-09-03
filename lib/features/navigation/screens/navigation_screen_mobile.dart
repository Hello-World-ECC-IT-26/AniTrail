import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/widgets/loading_screen.dart';
import '../../map/models/anime_spot.dart';
import '../models/navigation_phase.dart';
import '../services/navigation_route_service.dart';
import '../widgets/direction_arrow.dart';
import '../widgets/navigation_mascot.dart';
import 'arrival_screen_mobile.dart';

class NavigationScreen extends StatefulWidget {
  final Spot spot;
  final String cardId;
  final int stampCount;
  final int stampTotal;
  final String? imageUrl;
  final LatLng? origin;

  const NavigationScreen({
    super.key,
    required this.spot,
    required this.cardId,
    this.stampCount = 0,
    this.stampTotal = 0,
    this.imageUrl,
    this.origin,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  static const _headingChannel = EventChannel('anitrail/device_heading');
  static const _walkingSpeedMetersPerSecond = 1.25;

  final _routeService = NavigationRouteService();
  final _arrivalEntryGuard = ArrivalEntryGuard();
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<dynamic>? _headingSubscription;
  Timer? _directionIntroTimer;
  LatLng? _currentLocation;
  List<LatLng> _routePoints = [];
  double? _remainingDistanceMeters;
  double? _remainingTimeSeconds;
  double? _deviceHeadingDegrees;
  bool _showCompassSwitchNotice = false;
  bool _locationPermissionPermanentlyDenied = false;
  bool _locationServiceDisabled = false;
  bool _headingUnavailable = false;
  bool _loading = true;
  String? _error;

  Spot get spot => widget.spot;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.origin;
    _loadRoute();
    _startLocationTracking();
  }

  Future<void> _loadRoute() async {
    final destination = _destination;
    final origin = _currentLocation;
    if (destination == null) {
      setState(() {
        _loading = false;
        _error = '目的地の位置情報がありません';
      });
      return;
    }
    if (origin == null) {
      setState(() {
        _loading = false;
        _error = '現在地が取得できていません';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final route = await _routeService.fetchWalkingRoute(
        origin: origin,
        destination: destination,
      );
      if (!mounted) return;
      setState(() {
        _routePoints = route.points;
        _remainingDistanceMeters = route.distanceMeters;
        _remainingTimeSeconds = route.durationSeconds;
        _loading = false;
      });
      _updateRemainingDistance();
      await _fitRoute();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '徒歩ルート作成に失敗しました: $e';
      });
    }
  }

  Future<void> _startLocationTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        setState(() {
          _locationServiceDisabled = true;
          _error = '位置情報サービスが無効です。設定から有効にしてください';
        });
      }
      return;
    }
    if (mounted) setState(() => _locationServiceDisabled = false);
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _locationPermissionPermanentlyDenied =
              permission == LocationPermission.deniedForever;
          _error = permission == LocationPermission.deniedForever
              ? '位置情報の権限が無効です。設定から許可してください'
              : 'ナビには位置情報の権限が必要です';
        });
      }
      return;
    }
    try {
      final position = await Geolocator.getCurrentPosition();
      _setCurrentLocation(position);
      if (widget.origin == null && _routePoints.isEmpty) {
        await _loadRoute();
      }
    } catch (error) {
      if (mounted) setState(() => _error = '現在地を取得できませんでした: $error');
    }
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen(
          _setCurrentLocation,
          onError: (Object error) {
            if (mounted) setState(() => _error = '位置情報を更新できませんでした: $error');
          },
        );
  }

  void _startDeviceHeadingTracking() {
    if (_headingSubscription != null) return;
    _headingSubscription = _headingChannel.receiveBroadcastStream().listen(
      (event) {
        if (!mounted) return;
        if (event == null) {
          setState(() {
            _deviceHeadingDegrees = null;
            _headingUnavailable = true;
          });
          return;
        }
        if (event is! num) return;
        setState(() {
          _deviceHeadingDegrees = _normalizeDegrees(event.toDouble());
          _headingUnavailable = false;
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _deviceHeadingDegrees = null;
          _headingUnavailable = true;
        });
      },
      cancelOnError: false,
    );
  }

  Future<void> _stopDeviceHeadingTracking() async {
    final subscription = _headingSubscription;
    if (subscription == null) return;
    _headingSubscription = null;
    await subscription.cancel();
    if (!mounted) return;
    setState(() {
      _deviceHeadingDegrees = null;
    });
  }

  void _syncDirectionModeResources(bool isDirectionMode) {
    if (isDirectionMode) {
      _startDeviceHeadingTracking();
    } else {
      unawaited(_stopDeviceHeadingTracking());
    }
  }

  void _setCurrentLocation(Position position) {
    if (!mounted) return;
    final wasNearDestination = _isNearDestination;
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      if (!wasNearDestination && _isNearDestination && !_hasArrived) {
        _showCompassSwitchNotice = true;
      } else if (!_isNearDestination) {
        _showCompassSwitchNotice = false;
      }
    });
    if (_showCompassSwitchNotice) {
      _directionIntroTimer?.cancel();
      _directionIntroTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showCompassSwitchNotice = false);
      });
    }
    _updateRemainingDistance();
  }

  void _updateRemainingDistance() {
    final current = _currentLocation;
    if (current == null || _routePoints.length < 2) return;
    final nearestIndex = _nearestRoutePointIndex(current);
    var remaining = _distanceMeters(current, _routePoints[nearestIndex]);
    for (var i = nearestIndex; i < _routePoints.length - 1; i++) {
      remaining += _distanceMeters(_routePoints[i], _routePoints[i + 1]);
    }
    setState(() {
      _remainingDistanceMeters = remaining;
      _remainingTimeSeconds = remaining / _walkingSpeedMetersPerSecond;
    });
  }

  int _nearestRoutePointIndex(LatLng current) {
    var nearestIndex = 0;
    var nearestDistance = double.infinity;
    for (var i = 0; i < _routePoints.length; i++) {
      final distance = _distanceMeters(current, _routePoints[i]);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = i;
      }
    }
    return nearestIndex;
  }

  LatLng? get _destination {
    final lat = spot.latitude;
    final lng = spot.longitude;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  double? get _distanceToDestinationMeters {
    final current = _currentLocation;
    final destination = _destination;
    if (current == null || destination == null) return null;
    return _distanceMeters(current, destination);
  }

  bool get _isNearDestination {
    return _navigationPhase != NavigationPhase.route;
  }

  NavigationPhase get _navigationPhase =>
      navigationPhaseForDistance(_distanceToDestinationMeters);

  bool get _hasArrived => _navigationPhase == NavigationPhase.arrived;

  bool get _isDirectionMode => _isNearDestination && !_hasArrived;

  void _openArrivalScreen() {
    if (!mounted || !_arrivalEntryGuard.claim(_navigationPhase)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      await _stopDeviceHeadingTracking();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement<bool, bool>(
        MaterialPageRoute(
          builder: (_) => ArrivalScreen(
            spot: spot,
            cardId: widget.cardId,
            stampCount: widget.stampCount,
            stampTotal: widget.stampTotal,
            imageUrl: widget.imageUrl,
          ),
        ),
      );
    });
  }

  Set<Marker> get _markers {
    final destination = _destination;
    return {
      if (_currentLocation != null)
        Marker(
          markerId: const MarkerId('current'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: '現在地'),
        ),
      if (destination != null)
        Marker(
          markerId: const MarkerId('destination'),
          position: destination,
          infoWindow: InfoWindow(title: spot.name),
        ),
    };
  }

  Set<Polyline> get _polylines => {
    if (_routePoints.length >= 2)
      Polyline(
        polylineId: const PolylineId('valhalla_route'),
        points: _routePoints,
        color: AppColors.primary,
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
  };

  Future<void> _fitRoute() async {
    final controller = _mapController;
    if (controller == null) return;
    final points = [?_currentLocation, ..._routePoints, ?_destination];
    if (points.isEmpty) return;
    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 16),
      );
      return;
    }
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        72,
      ),
    );
  }

  @override
  void dispose() {
    _directionIntroTimer?.cancel();
    _positionSubscription?.cancel();
    _headingSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialTarget =
        _currentLocation ?? _destination ?? const LatLng(34.702, 135.496);
    final hasArrived = _hasArrived;
    if (hasArrived) {
      _openArrivalScreen();
      return const Scaffold(body: AppLoadingScreen(message: '到着画面を開いています・・・'));
    }
    final isDirectionMode = _isDirectionMode;
    _syncDirectionModeResources(isDirectionMode);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 16,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            markers: isDirectionMode ? const {} : _markers,
            polylines: isDirectionMode ? const {} : _polylines,
            onMapCreated: (controller) async {
              _mapController = controller;
              await _fitRoute();
            },
          ),
          if (isDirectionMode) ...[
            Positioned.fill(
              child: ColoredBox(color: AppColors.black.withValues(alpha: 0.58)),
            ),
            // 下部バーとキャラクターをデザインどおり画面下端まで配置する。
            SafeArea(bottom: false, child: _buildDirectionMode()),
            if (_showCompassSwitchNotice)
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Material(
                      color: AppColors.primary,
                      borderRadius: AppRadius.brLg,
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(
                          '聖地が近いため、方向案内に切り替えました',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ] else ...[
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _buildTopDistanceBar(context),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: _buildDestinationCard(),
                ),
              ),
            ),
          ],
          if (_error != null && !isDirectionMode)
            Positioned(
              left: 16,
              right: 16,
              bottom: 172,
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_error!, style: AppTextStyles.body),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_locationPermissionPermanentlyDenied)
                            TextButton(
                              onPressed: Geolocator.openAppSettings,
                              child: const Text('設定を開く'),
                            ),
                          if (_locationServiceDisabled)
                            TextButton(
                              onPressed: Geolocator.openLocationSettings,
                              child: const Text('位置情報設定'),
                            ),
                          TextButton(
                            onPressed: () async {
                              setState(() {
                                _error = null;
                                _locationPermissionPermanentlyDenied = false;
                                _locationServiceDisabled = false;
                              });
                              await _startLocationTracking();
                              if (_currentLocation != null) await _loadRoute();
                            },
                            child: const Text('再試行'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_loading && !isDirectionMode)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildDirectionMode() {
    final deviceHeading = _deviceHeadingDegrees;
    final bearing = _bearingToDestination();
    final relativeBearing = deviceHeading == null
        ? null
        : _normalizeDegrees(bearing - deviceHeading);
    final distance = _distanceToDestinationMeters ?? _remainingDistanceMeters;

    return LayoutBuilder(
      builder: (context, constraints) {
        const distanceCardTop = 96.0;
        const compassTop = 246.0;
        const bottomContentReserve = 178.0;
        final distanceCardWidth = math.min(
          346.0,
          math.max(0.0, constraints.maxWidth - AppSpacing.xxl * 2),
        );
        final compassSize = math.max(
          0.0,
          math.min(
            338.0,
            math.min(
              math.max(0.0, constraints.maxWidth - 102),
              math.max(
                0.0,
                constraints.maxHeight - compassTop - bottomContentReserve,
              ),
            ),
          ),
        );

        return Stack(
          children: [
            Positioned(
              left: 28,
              top: 36,
              child: IconButton(
                icon: const Icon(
                  Icons.chevron_left,
                  color: AppColors.white,
                  size: 36,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              top: distanceCardTop,
              left: (constraints.maxWidth - distanceCardWidth) / 2,
              width: distanceCardWidth,
              child: _buildDirectionDistanceCard(distance),
            ),
            Positioned(
              top: compassTop,
              left: 0,
              right: 0,
              child: Center(
                child: DirectionArrow(
                  deviceHeadingDegrees: deviceHeading,
                  size: compassSize,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 32,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFFFB44C), width: 5),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF9B4811), Color(0xFF0B0502)],
                  ),
                ),
              ),
            ),
            Positioned(left: -14, bottom: -46, child: const NavigationMascot()),
            Positioned(
              right: 22,
              bottom: 86,
              width: math.min(210.0, math.max(0.0, constraints.maxWidth - 190)),
              height: 128,
              child: _buildDirectionSpeechBubble(relativeBearing),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDirectionDistanceCard(double? distance) {
    return Material(
      color: AppColors.black.withValues(alpha: 0.86),
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 112,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '目的地まで',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDistance(distance),
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 58,
                fontWeight: FontWeight.w700,
                height: 0.95,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionSpeechBubble(double? relativeBearing) {
    final message = _directionMessageFor(relativeBearing);
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: _headingUnavailable
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '方位を取得できません',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _stopDeviceHeadingTracking();
                      _startDeviceHeadingTracking();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('方位を再取得'),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    message,
                    softWrap: false,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  String _directionMessageFor(double? relativeBearing) {
    if (relativeBearing == null) return '方角合ってるよ\nこのまま進もう！';

    final signed = relativeBearing > 180
        ? relativeBearing - 360
        : relativeBearing;
    final absolute = signed.abs();
    if (absolute <= 20) return '方角合ってるよ\nこのまま進もう！';
    if (absolute >= 160) return '後ろ方向だよ！\n向きを変えて進もう！';

    final side = signed > 0 ? '右' : '左';
    return '$side方向だよ！\n$sideへ向いて進もう！';
  }

  Widget _buildTopDistanceBar(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.brLg,
      elevation: 4,
      shadowColor: AppColors.black.withValues(alpha: 0.18),
      child: SizedBox(
        height: 96,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF12265A)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '目的地まであと',
                    style: AppTextStyles.body.copyWith(
                      color: const Color(0xFF12265A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatDistance(_remainingDistanceMeters),
                    style: AppTextStyles.title.copyWith(
                      color: const Color(0xFF12265A),
                      fontSize: 30,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationCard() {
    final progress = widget.stampTotal <= 0
        ? 0.0
        : (widget.stampCount / widget.stampTotal).clamp(0.0, 1.0).toDouble();
    final stampText = widget.stampTotal <= 0
        ? '${widget.stampCount}/0'
        : '${widget.stampCount}/${widget.stampTotal}';
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.brLg,
      elevation: 6,
      shadowColor: AppColors.black.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: AppRadius.brSm,
                  child: SizedBox(
                    width: 128,
                    height: 84,
                    child: _buildCardImage(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spot.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.subtitle.copyWith(
                          color: const Color(0xFF12265A),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if ((spot.animeTitle ?? '').isNotEmpty)
                        Text(
                          spot.animeTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF12265A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (spot.addressText.isNotEmpty)
                        Text(
                          spot.addressText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF12265A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(
                  'スタンプラリー',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  stampText,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppColors.borderLight,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            if (_remainingTimeSeconds != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '徒歩 ${_formatDuration(_remainingTimeSeconds!)}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardImage() {
    final url = widget.imageUrl;
    if (url == null || url.isEmpty) {
      return Container(color: AppColors.placeholder);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, imageUrl) =>
          Container(color: AppColors.placeholder),
      errorWidget: (context, imageUrl, error) =>
          Container(color: AppColors.placeholder),
    );
  }

  String _formatDistance(double? meters) {
    if (meters == null || meters.isNaN || meters.isInfinite) return '-';
    if (meters >= 1000) {
      final km = meters / 1000;
      final text = km >= 10 ? km.round().toString() : km.toStringAsFixed(1);
      return '${text}km';
    }
    return '${meters.round()}m';
  }

  String _formatDuration(double seconds) {
    if (seconds.isNaN || seconds.isInfinite || seconds <= 0) return '-';
    final minutes = (seconds / 60).ceil();
    if (minutes < 60) return '$minutes分';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours時間' : '$hours時間$rest分';
  }

  double _bearingToDestination() {
    final current = _currentLocation;
    final destination = _destination;
    if (current == null || destination == null) return 0;
    return _normalizeDegrees(
      Geolocator.bearingBetween(
        current.latitude,
        current.longitude,
        destination.latitude,
        destination.longitude,
      ),
    );
  }

  double _normalizeDegrees(double degrees) {
    final normalized = degrees % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  double _distanceMeters(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }
}
