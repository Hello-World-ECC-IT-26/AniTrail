import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/widgets/loading_screen.dart';
import '../../map/models/anime_spot.dart';
import '../../map/services/spot_api.dart';
import '../../coupon/data/coupon_repository.dart';
import '../../coupon/models/coupon.dart';
import '../../coupon/widgets/coupon_detail.dart';
import '../../coupon/widgets/coupon_grant_dialog.dart';
import '../../home/screens/home_screen.dart';
import '../../spot/screens/spot_comments_screen.dart';
import '../../stamp/screens/stamp_screen.dart';
import '../models/arrival_step.dart';
import '../services/navigation_route_service.dart';
import '../widgets/direction_arrow.dart';
import '../widgets/navigation_mascot.dart';

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
  static const _directionModeDistanceMeters = 500.0;
  static const _arrivalDistanceMeters = 20.0;

  final _routeService = NavigationRouteService();
  final _spotApi = SpotApi();
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<dynamic>? _headingSubscription;
  Timer? _directionIntroTimer;
  LatLng? _currentLocation;
  List<LatLng> _routePoints = [];
  double? _remainingDistanceMeters;
  double? _remainingTimeSeconds;
  double? _deviceHeadingDegrees;
  bool _directionIntroDismissed = false;
  bool _showDirectionIntroDetails = false;
  bool _directionIntroTimerStarted = false;
  ArrivalStep _arrivalStep = ArrivalStep.arrived;
  XFile? _capturedPhoto;
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
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    try {
      final position = await Geolocator.getCurrentPosition();
      _setCurrentLocation(position);
      if (widget.origin == null && _routePoints.isEmpty) {
        await _loadRoute();
      }
    } catch (_) {}
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_setCurrentLocation);
  }

  void _startDeviceHeadingTracking() {
    if (_headingSubscription != null) return;
    _headingSubscription = _headingChannel.receiveBroadcastStream().listen(
      (event) {
        if (!mounted) return;
        if (event == null) {
          setState(() {
            _deviceHeadingDegrees = null;
          });
          return;
        }
        if (event is! num) return;
        setState(() {
          _deviceHeadingDegrees = _normalizeDegrees(event.toDouble());
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _deviceHeadingDegrees = null;
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

  Future<void> _takeArrivalPhoto() async {
    try {
      final photo = await ImagePicker().pickImage(source: ImageSource.camera);
      if (!mounted || photo == null) return;
      setState(() {
        _capturedPhoto = photo;
        _arrivalStep = ArrivalStep.confirmPhoto;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('カメラを起動できませんでした: $e')));
    }
  }

  Future<void> _createArrivalStamp() async {
    setState(() {
      _arrivalStep = ArrivalStep.creatingStamp;
    });
    try {
      final stampResult = await _spotApi.createStamp(
        cardId: widget.cardId,
        spotId: spot.spotId,
      );
      Object? photoError;
      final photo = _capturedPhoto;
      if (photo != null) {
        try {
          await _spotApi.uploadArrivalPhoto(
            spotId: spot.spotId,
            stampId: stampResult.stampId,
            bytes: await photo.readAsBytes(),
            filename: photo.name,
            contentType: photo.mimeType,
          );
        } catch (error) {
          photoError = error;
        }
      }
      if (!mounted) return;
      setState(() {
        _arrivalStep = ArrivalStep.stampEarned;
      });
      if (photoError != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('写真を保存できませんでした: $photoError')));
      }
      if (stampResult.newGrants.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_showEarnedCoupons(stampResult.newGrants));
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _arrivalStep = ArrivalStep.action;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('スタンプの記録に失敗しました: $e')));
    }
  }

  Future<void> _showEarnedCoupons(List<CouponGrant> grants) async {
    final viewCoupons = await showCouponGrantDialog(context, grants);
    if (!mounted) return;
    final repository = context.read<CouponRepository>();
    try {
      await Future.wait(
        grants.map((grant) => repository.markGrantSeen(grant.grantId)),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('獲得通知の確認に失敗しました: $error')));
      }
    }
    if (!viewCoupons || !mounted) return;
    try {
      if (repository.category != null) {
        await repository.setCategory(null);
      } else {
        await repository.load(refresh: true);
      }
      if (!mounted) return;
      if (grants.length == 1) {
        final couponId = grants.single.couponId;
        final coupon = repository.coupons
            .where((item) => item.id == couponId)
            .firstOrNull;
        if (coupon != null) {
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => CouponDetailScreen(coupon: coupon),
            ),
          );
          return;
        }
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 3)),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('クーポンを開けませんでした: $error')));
      }
    }
  }

  void _syncDirectionModeResources(bool isDirectionMode) {
    if (isDirectionMode) {
      _startDeviceHeadingTracking();
    } else {
      unawaited(_stopDeviceHeadingTracking());
    }
  }

  void _syncDirectionIntroResources(bool showDirectionIntro) {
    if (!showDirectionIntro) {
      _directionIntroTimer?.cancel();
      _directionIntroTimer = null;
      _directionIntroTimerStarted = false;
      return;
    }
    if (_directionIntroTimerStarted) return;
    _directionIntroTimerStarted = true;
    _directionIntroTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted || !_isNearDestination || _directionIntroDismissed) return;
      setState(() {
        _showDirectionIntroDetails = true;
      });
    });
  }

  void _setCurrentLocation(Position position) {
    if (!mounted) return;
    final wasNearDestination = _isNearDestination;
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      if (wasNearDestination && !_isNearDestination) {
        _showDirectionIntroDetails = false;
      }
    });
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
    final distance = _distanceToDestinationMeters;
    return distance != null && distance <= _directionModeDistanceMeters;
  }

  bool get _hasArrived {
    final distance = _distanceToDestinationMeters;
    return distance != null && distance <= _arrivalDistanceMeters;
  }

  bool get _isDirectionMode =>
      _isNearDestination && _directionIntroDismissed && !_hasArrived;

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
    final isDirectionMode = _isDirectionMode;
    final showDirectionIntro =
        _isNearDestination && !_directionIntroDismissed && !hasArrived;
    final isFullScreenArrivalStep =
        _arrivalStep == ArrivalStep.stampEarned ||
        _arrivalStep == ArrivalStep.creatingStamp;
    final arrivalOverlayAlpha = _arrivalStep == ArrivalStep.stampEarned
        ? 0.74
        : 0.48;
    _syncDirectionModeResources(isDirectionMode);
    _syncDirectionIntroResources(showDirectionIntro);
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
            markers: hasArrived || isDirectionMode || showDirectionIntro
                ? const {}
                : _markers,
            polylines: hasArrived || isDirectionMode || showDirectionIntro
                ? const {}
                : _polylines,
            onMapCreated: (controller) async {
              _mapController = controller;
              await _fitRoute();
            },
          ),
          if (hasArrived) ...[
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.black.withValues(alpha: arrivalOverlayAlpha),
              ),
            ),
            if (isFullScreenArrivalStep)
              Positioned.fill(child: _buildArrivalFlow())
            else
              SafeArea(child: _buildArrivalFlow()),
          ] else if (isDirectionMode) ...[
            Positioned.fill(
              child: ColoredBox(color: AppColors.black.withValues(alpha: 0.58)),
            ),
            SafeArea(child: _buildDirectionMode()),
          ] else if (showDirectionIntro) ...[
            Positioned.fill(
              child: ColoredBox(color: AppColors.black.withValues(alpha: 0.58)),
            ),
            SafeArea(child: _buildDirectionIntro()),
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
          if (_error != null &&
              !hasArrived &&
              !isDirectionMode &&
              !showDirectionIntro)
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
                  child: Text(_error!, style: AppTextStyles.body),
                ),
              ),
            ),
          if (_loading &&
              !hasArrived &&
              !isDirectionMode &&
              !showDirectionIntro)
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
    final bearing = _bearingToDestination();
    final deviceHeading = _deviceHeadingDegrees;
    final relativeBearing = deviceHeading == null
        ? null
        : _normalizeDegrees(bearing - deviceHeading);
    final distance = _distanceToDestinationMeters ?? _remainingDistanceMeters;
    final statusText = distance != null && distance <= 30
        ? 'まもなく聖地だよ！'
        : 'あと ${_formatDistance(distance)}';

    return LayoutBuilder(
      builder: (context, constraints) {
        // 方位表示に使える横幅を優先しつつ、案内パネルと重ならない最大径にする。
        final compassSize = math
            .min(
              constraints.maxWidth - AppSpacing.md * 2,
              constraints.maxHeight - 226,
            )
            .clamp(220.0, 440.0)
            .toDouble();

        return Stack(
          children: [
            Positioned(
              left: AppSpacing.md,
              top: AppSpacing.xs,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.xxxl,
              right: AppSpacing.xxxl,
              child: Column(
                children: [
                  Text(
                    '目的地方向',
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.white.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    deviceHeading == null
                        ? '端末方位取得中'
                        : '${bearing.round()}° ${_directionLabel(bearing)}',
                    style: AppTextStyles.title.copyWith(
                      color: AppColors.white,
                      fontSize: 38,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 94,
              left: 0,
              right: 0,
              bottom: 132,
              child: Center(
                child: DirectionArrow(
                  deviceHeadingDegrees: deviceHeading,
                  size: compassSize,
                ),
              ),
            ),
            Positioned(
              right: AppSpacing.md,
              bottom: 108,
              child: const NavigationMascot(),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Material(
                color: AppColors.black.withValues(alpha: 0.78),
                borderRadius: AppRadius.brMd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '目的地まで',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        statusText,
                        style: AppTextStyles.title.copyWith(
                          color: AppColors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (relativeBearing != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _relativeDirectionText(relativeBearing),
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.white.withValues(alpha: 0.78),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDirectionIntro() {
    final distance = _distanceToDestinationMeters ?? _remainingDistanceMeters;
    return Stack(
      children: [
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 520),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _showDirectionIntroDetails
                  ? _buildDirectionIntroDetailCard(
                      key: const ValueKey('detail'),
                    )
                  : _buildNearDestinationCard(
                      key: const ValueKey('near'),
                      distance: distance,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNearDestinationCard({
    required Key key,
    required double? distance,
  }) {
    return Material(
      key: key,
      color: const Color(0xFFEAF6FF),
      borderRadius: AppRadius.brLg,
      elevation: 8,
      shadowColor: AppColors.black.withValues(alpha: 0.24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ClipRRect(
          borderRadius: AppRadius.brLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Text(
                  'もうすぐだよ！',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title.copyWith(
                    color: const Color(0xFF12265A),
                    fontSize: 34,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 180,
                child: Image.asset(
                  'assets/images/weasel.png',
                  fit: BoxFit.contain,
                  cacheWidth: 360,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                color: AppColors.white.withValues(alpha: 0.96),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: Text(
                  distance == null
                      ? 'エラー'
                      : '目的地まで後 ${_formatSpacedDistance(distance)}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle.copyWith(
                    color: const Color(0xFF12265A),
                    fontSize: 26,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionIntroDetailCard({required Key key}) {
    return Material(
      key: key,
      color: const Color(0xFFEAF6FF),
      borderRadius: AppRadius.brLg,
      elevation: 8,
      shadowColor: AppColors.black.withValues(alpha: 0.24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ClipRRect(
          borderRadius: AppRadius.brLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Text(
                  '探索モード',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title.copyWith(
                    color: const Color(0xFF12265A),
                    fontSize: 34,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 160,
                child: Image.asset(
                  'assets/images/weasel.png',
                  fit: BoxFit.contain,
                  cacheWidth: 360,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                color: AppColors.white.withValues(alpha: 0.96),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ここからは方位だけを頼りに進んでいくよ',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.subtitle.copyWith(
                        color: const Color(0xFF12265A),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _directionIntroDismissed = true;
                          });
                        },
                        child: Text(
                          'レッツゴー',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'ナビの見方は、目的地までの距離が500m以内になると表示されます。探索モードでは、方位だけを頼りに進んでください。',
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'ナビの見方',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArrivalCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Material(
          color: AppColors.surface,
          borderRadius: AppRadius.brLg,
          elevation: 10,
          shadowColor: AppColors.black.withValues(alpha: 0.28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ClipRRect(
              borderRadius: AppRadius.brLg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _buildArrivalImage(fit: BoxFit.cover),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.xs,
                    ),
                    child: Column(
                      children: [
                        Text(
                          spot.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.title.copyWith(
                            color: const Color(0xFF12265A),
                            fontSize: 32,
                          ),
                        ),
                        if ((spot.animeTitle ?? '').isNotEmpty)
                          Text(
                            'アニメ「${spot.animeTitle}」',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              color: const Color(0xFF12265A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF6FF),
                        borderRadius: AppRadius.brMd,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '聖地に到着したよ！',
                              style: AppTextStyles.subtitle.copyWith(
                                color: const Color(0xFF12265A),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              height: 180,
                              child: Image.asset(
                                'assets/images/weasel.png',
                                fit: BoxFit.contain,
                                cacheWidth: 360,
                                filterQuality: FilterQuality.medium,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _arrivalStep = ArrivalStep.action;
                                  });
                                },
                                child: Text(
                                  'つぎへ',
                                  style: AppTextStyles.button.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArrivalFlow() {
    return switch (_arrivalStep) {
      ArrivalStep.arrived => _buildArrivalCard(),
      ArrivalStep.action => _buildArrivalAction(),
      ArrivalStep.confirmPhoto => _buildPhotoConfirm(),
      ArrivalStep.creatingStamp => _buildStampCreating(),
      ArrivalStep.stampEarned => _buildStampEarned(),
      ArrivalStep.detail => _buildStampDetail(),
    };
  }

  Widget _buildArrivalAction() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Material(
          color: AppColors.surface,
          borderRadius: AppRadius.brLg,
          elevation: 10,
          shadowColor: AppColors.black.withValues(alpha: 0.28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ClipRRect(
              borderRadius: AppRadius.brLg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _buildArrivalImage(fit: BoxFit.cover),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.xs,
                    ),
                    child: Column(
                      children: [
                        Text(
                          spot.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.title.copyWith(
                            color: const Color(0xFF12265A),
                            fontSize: 32,
                          ),
                        ),
                        if ((spot.animeTitle ?? '').isNotEmpty)
                          Text(
                            'アニメ「${spot.animeTitle}」',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              color: const Color(0xFF12265A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF6FF),
                        borderRadius: AppRadius.brMd,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '記念の写真を撮りますか',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.subtitle.copyWith(
                                color: const Color(0xFF12265A),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              height: 180,
                              child: Image.asset(
                                'assets/images/weasel.png',
                                fit: BoxFit.contain,
                                cacheWidth: 360,
                                filterQuality: FilterQuality.medium,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),
                                ),
                                onPressed: _takeArrivalPhoto,
                                child: Text(
                                  '写真を撮る',
                                  style: AppTextStyles.button.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _capturedPhoto = null;
                                  });
                                  unawaited(_createArrivalStamp());
                                },
                                child: Text(
                                  'スキップする',
                                  style: AppTextStyles.button.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoConfirm() {
    final photo = _capturedPhoto;
    return ColoredBox(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: AppRadius.brSm,
                child: photo == null
                    ? Container(color: AppColors.placeholder)
                    : Image.file(
                        File(photo.path),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'この写真を使いますか',
              style: AppTextStyles.subtitle.copyWith(
                color: const Color(0xFF12265A),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _takeArrivalPhoto,
                    child: const Text('撮り直し'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: _createArrivalStamp,
                    child: const Text('写真を使う'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStampCreating() {
    return const AppLoadingScreen(message: 'スタンプを記録しています・・・', imageSize: 220);
  }

  Widget _buildStampEarned() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stampSize = math.min(constraints.maxWidth * 0.9, 390.0);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xxxl,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                const Spacer(flex: 1),
                Text(
                  'スタンプ獲得！',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.white,
                    fontSize: 36,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                _buildStampBadge(showPhoto: false, size: stampSize),
                const SizedBox(height: AppSpacing.lg),
                if ((spot.animeTitle ?? '').isNotEmpty)
                  Text(
                    'アニメ「${spot.animeTitle}」',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.white.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const Spacer(flex: 2),
                SizedBox(
                  width: 252,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StampScreen(
                            cardId: widget.cardId,
                            animeId: spot.animeId,
                            animeTitle: spot.animeTitle,
                            recentlyObtainedSpotId: spot.spotId,
                          ),
                        ),
                      );
                    },
                    child: const Text('コレクションを見る'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: 252,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SpotCommentsScreen(
                            spot: spot,
                            animeTitle: spot.animeTitle ?? '',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('コメントする'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    '閉じる',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStampDetail() {
    return ColoredBox(
      color: AppColors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  onPressed: () {
                    setState(() {
                      _arrivalStep = ArrivalStep.stampEarned;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    spot.animeTitle ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: const Color(0xFF12265A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${widget.stampCount + 1}/${math.max(widget.stampTotal, 1)}',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                children: [
                  Material(
                    color: AppColors.surface,
                    borderRadius: AppRadius.brMd,
                    elevation: 4,
                    shadowColor: AppColors.black.withValues(alpha: 0.18),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ),
                          _buildStampBadge(showPhoto: false, size: 220),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            spot.name,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.subtitle.copyWith(
                              color: const Color(0xFF12265A),
                            ),
                          ),
                          if ((spot.animeTitle ?? '').isNotEmpty)
                            Text(
                              'アニメ「${spot.animeTitle}」',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFF12265A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          const SizedBox(height: AppSpacing.lg),
                          ClipRRect(
                            borderRadius: AppRadius.brSm,
                            child: _capturedPhoto == null
                                ? _buildArrivalImage(fit: BoxFit.cover)
                                : Image.file(
                                    File(_capturedPhoto!.path),
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.medium,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('閉じる'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStampBadge({required bool showPhoto, required double size}) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/stamp_sample.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            cacheWidth: (size * 2).round(),
            filterQuality: FilterQuality.medium,
          ),
          Positioned(
            left: size * 0.17,
            right: size * 0.17,
            bottom: size * 0.13,
            height: size * 0.1,
            child: CustomPaint(
              painter: _ArchedStampLabelPainter(
                text: spot.name,
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xFF12265A),
                  fontSize: size * 0.075,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
          if (showPhoto && _capturedPhoto != null)
            Positioned(
              right: size * 0.08,
              bottom: size * 0.18,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 4),
                ),
                child: ClipOval(
                  child: Image.file(
                    File(_capturedPhoto!.path),
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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

  Widget _buildArrivalImage({required BoxFit fit}) {
    final url = widget.imageUrl;
    if (url == null || url.isEmpty) {
      return Container(
        color: const Color(0xFF0E6EA8),
        child: const Icon(Icons.landscape, color: AppColors.white, size: 64),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
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

  String _formatSpacedDistance(double meters) {
    final formatted = _formatDistance(
      meters,
    ).replaceAll('km', 'ｋｍ').replaceAll('m', 'ｍ');
    return formatted.split('').join(' ');
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

  String _directionLabel(double degrees) {
    const labels = ['北', '北東', '東', '南東', '南', '南西', '西', '北西'];
    final index = ((degrees + 22.5) / 45).floor() % labels.length;
    return labels[index];
  }

  String _relativeDirectionText(double relativeDegrees) {
    final signed = relativeDegrees > 180
        ? relativeDegrees - 360
        : relativeDegrees;
    final abs = signed.abs().round();
    if (abs <= 12) return 'そのまままっすぐ進んでください';
    if (abs >= 168) return '後ろ方向に目的地があります';

    final side = signed > 0 ? '右' : '左';
    if (abs < 45) return '少し$sideへ向いて進んでください';
    if (abs < 100) return '$side方向に進んでください';
    return '$side後ろ方向に目的地があります';
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

class _ArchedStampLabelPainter extends CustomPainter {
  final String text;
  final TextStyle style;

  const _ArchedStampLabelPainter({required this.text, required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    if (text.isEmpty || size.width <= 0 || size.height <= 0) return;

    var fontSize = style.fontSize ?? 18;
    final maxTextWidth = size.width * 0.96;
    final chars = text.runes.map(String.fromCharCode).toList(growable: false);
    var painters = _buildPainters(chars, fontSize);
    var totalWidth = _totalWidth(painters);

    if (totalWidth > maxTextWidth && totalWidth > 0) {
      fontSize *= maxTextWidth / totalWidth;
      painters = _buildPainters(chars, fontSize);
      totalWidth = _totalWidth(painters);
    }

    final archDepth = size.height * 0.26;
    final baselineY = size.height * 0.5 - archDepth * 0.25;
    var cursor = (size.width - totalWidth) / 2;

    for (final painter in painters) {
      final charWidth = painter.width;
      final centerX = cursor + charWidth / 2;
      final normalizedX = ((centerX - size.width / 2) / (size.width / 2)).clamp(
        -1.0,
        1.0,
      );
      final y = baselineY + archDepth * normalizedX * normalizedX;
      final slope = (2 * archDepth * normalizedX) / (size.width / 2);
      final angle = math.atan(slope);

      canvas.save();
      canvas.translate(centerX, y);
      canvas.rotate(angle);
      painter.paint(canvas, Offset(-charWidth / 2, -painter.height / 2));
      canvas.restore();
      cursor += charWidth;
    }
  }

  List<TextPainter> _buildPainters(List<String> chars, double fontSize) {
    return chars
        .map(
          (char) => TextPainter(
            text: TextSpan(
              text: char,
              style: style.copyWith(fontSize: fontSize),
            ),
            textDirection: TextDirection.ltr,
          )..layout(),
        )
        .toList(growable: false);
  }

  double _totalWidth(List<TextPainter> painters) {
    return painters.fold<double>(0, (width, painter) => width + painter.width);
  }

  @override
  bool shouldRepaint(covariant _ArchedStampLabelPainter oldDelegate) {
    return text != oldDelegate.text || style != oldDelegate.style;
  }
}
