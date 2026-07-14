import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_shadows.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_chip.dart';
import '../../navigation/screens/navigation_screen.dart';
import '../../search/widgets/search_result_card.dart';
import '../models/anime_spot.dart';
import '../services/spot_api.dart';
import 'spot_list_item.dart';
import 'spot_photo_gallery.dart';

const _kSpotFilters = ['すべて', '訪問済み', '未訪問'];

/// マップ右上のしおりボタンで開くシート。
/// しおり一覧（アニメ画像カード）→ タップで聖地一覧（同じシート内）へドリルダウン。
/// 聖地一覧表示時はマップに聖地ピンを打つ。
class MapShioriSheet extends StatefulWidget {
  /// シートを閉じる
  final VoidCallback onClose;

  /// しおり選択時、その聖地一覧をマップにピン表示する
  final ValueChanged<List<Spot>> onShowSpots;

  /// 一覧に戻る等でピンをクリアする
  final VoidCallback onClearSpots;
  final ValueChanged<bool> onDetailVisibilityChanged;
  final LatLng? currentLocation;

  const MapShioriSheet({
    super.key,
    required this.onClose,
    required this.onShowSpots,
    required this.onClearSpots,
    required this.onDetailVisibilityChanged,
    this.currentLocation,
  });

  @override
  State<MapShioriSheet> createState() => _MapShioriSheetState();
}

class _MapShioriSheetState extends State<MapShioriSheet> {
  final SpotApi _api = SpotApi();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // しおり一覧
  List<StampCard> _cards = [];
  bool _loading = true;
  Object? _error;

  // ドリルダウン中のしおり（null なら一覧表示）
  StampCard? _selected;
  bool _spotsLoading = false;
  int _spotFilterIndex = 0;
  int _spotSortIndex = 0;
  Spot? _detailSpot;
  List<String> _detailPostUrls = [];
  Set<String> _visitedSpotIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cards = await _api.fetchStampCards();
      if (mounted) {
        setState(() {
          _cards = cards;
          _loading = false;
        });
        unawaited(_hydrateCards(cards.take(4).toList()));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _hydrateCards(List<StampCard> cards) async {
    final cached = await Future.wait(
      cards.map((card) => _api.readCachedStampCard(card.cardId)),
    );
    for (final card in cached.whereType<StampCard>()) {
      _replaceCard(card);
    }

    final details = await Future.wait(
      cards.map((card) async {
        try {
          return await _api.fetchStampCard(card.cardId);
        } catch (_) {
          return null;
        }
      }),
    );
    for (final card in details.whereType<StampCard>()) {
      _replaceCard(card);
    }
  }

  void _replaceCard(StampCard card) {
    if (!mounted) return;
    final index = _cards.indexWhere((item) => item.cardId == card.cardId);
    if (index < 0) return;
    setState(() => _cards[index] = card);
  }

  Map<String, String> get _authHeaders {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return token != null ? {'Authorization': 'Bearer $token'} : {};
  }

  List<StampCard> get _incompleteCards =>
      _cards.where((card) => card.complete != true).toList();

  Future<void> _openShiori(StampCard card) async {
    setState(() {
      _selected = card;
      _spotsLoading = card.spots.isEmpty;
      _spotFilterIndex = 0;
      _spotSortIndex = 0;
      _visitedSpotIds = {};
    });
    widget.onDetailVisibilityChanged(true);
    // 聖地（lat/lng 付き）を取得してピン表示
    try {
      final full = card.spots.isNotEmpty
          ? card
          : await _api.fetchStampCard(card.cardId);
      final visited = await _api.fetchVisitedSpotIds(card.cardId);
      if (!mounted || _selected?.cardId != card.cardId) return;
      setState(() {
        _selected = full;
        _spotsLoading = false;
        _visitedSpotIds = visited;
      });
      widget.onShowSpots(full.spots);
    } catch (_) {
      if (mounted) setState(() => _spotsLoading = false);
    }
  }

  void _backToList() {
    setState(() {
      _selected = null;
      _detailSpot = null;
      _detailPostUrls = [];
      _visitedSpotIds = {};
    });
    widget.onClearSpots();
    widget.onDetailVisibilityChanged(false);
  }

  void _backToSpotList() {
    setState(() {
      _detailSpot = null;
      _detailPostUrls = [];
    });
    final selected = _selected;
    if (selected != null) widget.onShowSpots(selected.spots);
  }

  void _dragSheetByDelta(double delta) {
    if (!_sheetController.isAttached) return;
    final height = MediaQuery.sizeOf(context).height;
    final next = (_sheetController.size - delta / height).clamp(0.3, 0.9);
    _sheetController.jumpTo(next);
  }

  double _distanceMeters(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371000.0;
    double toRad(double degree) => degree * math.pi / 180;
    final dLat = toRad(lat2 - lat1);
    final dLng = toRad(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRad(lat1)) *
            math.cos(toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  void _dragSheet(DragUpdateDetails details) {
    _dragSheetByDelta(details.primaryDelta ?? 0);
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
                boxShadow: AppShadows.sheet,
              ),
              child: Column(
                children: [
                  Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerMove: (event) => _dragSheetByDelta(event.delta.dy),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHandle(),
                        if (_selected != null && _detailSpot == null)
                          _buildHeader(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _selected == null
                        ? _buildShioriList(scrollController)
                        : _detailSpot != null
                        ? _buildSpotDetail(scrollController, _detailSpot!)
                        : _buildSpotList(scrollController, _selected!),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        width: AppSizes.sheetHandleWidth,
        height: AppSizes.sheetHandleHeight,
        decoration: BoxDecoration(
          color: AppColors.grey,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ── 詳細ヘッダー: 戻る + しおりタイトル ──
  Widget _buildHeader() {
    final selected = _selected!;
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textSecondary,
          onPressed: _backToList,
        ),
        Expanded(
          child: Text(
            selected.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.input.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: Text('聖地 ${selected.spotCount}箇所', style: AppTextStyles.label),
        ),
      ],
    );
  }

  // ── レベル0: しおり一覧（検索カード風） ──
  Widget _buildShioriList(ScrollController controller) {
    if (_loading) {
      return _buildScrollableState(
        controller,
        _buildLoadingAnimation('しおりを読み込んでいます・・・'),
      );
    }
    if (_error != null) {
      return _buildScrollableState(
        controller,
        _centerMessage('しおりを読み込めませんでした', retry: true),
      );
    }
    final cards = _incompleteCards;
    if (cards.isEmpty) {
      return _buildScrollableState(controller, _centerMessage('進行中のしおりはありません'));
    }
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      itemCount: cards.length,
      separatorBuilder: (context, i) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) {
        final card = cards[i];
        return SearchResultCard(
          title: card.title,
          bannerImage: card.keyVisualUrls.firstOrNull,
          spotCount: card.spotCount,
          spotImages: card.spotImageUrls,
          httpHeaders: _authHeaders,
          variableSpotImages: true,
          onBannerVerticalDragUpdate: _dragSheet,
          onViewSpots: () => _openShiori(card),
        );
      },
    );
  }

  // ── レベル1: 聖地一覧 ──
  Widget _buildSpotList(ScrollController controller, StampCard card) {
    if (_spotsLoading) {
      return _buildScrollableState(
        controller,
        _buildLoadingAnimation('聖地を読み込んでいます・・・'),
      );
    }
    final allSpots = card.spots;
    if (allSpots.isEmpty) {
      return _buildScrollableState(controller, _centerMessage('聖地が登録されていません'));
    }
    final spots = allSpots.where((spot) {
      final stamped = _visitedSpotIds.contains(spot.spotId);
      return switch (_spotFilterIndex) {
        1 => stamped,
        2 => !stamped,
        _ => true,
      };
    }).toList();
    final spotsWithDistance = spots.map(_withComputedDistance).toList();
    if (_spotSortIndex == 0) {
      spotsWithDistance.sort((a, b) {
        final ad = a.distanceM;
        final bd = b.distanceM;
        if (ad == null && bd == null) return a.name.compareTo(b.name);
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });
    } else {
      spotsWithDistance.sort((a, b) => a.name.compareTo(b.name));
    }
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      itemCount: spotsWithDistance.isEmpty ? 2 : spotsWithDistance.length + 1,
      separatorBuilder: (context, i) => i == 0
          ? const Divider(height: 1)
          : const Divider(height: 1, indent: 16),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: _buildSpotListControls(),
          );
        }
        if (spotsWithDistance.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Center(
              child: Text('該当する聖地はありません', style: AppTextStyles.hint),
            ),
          );
        }
        final spot = spotsWithDistance[i - 1];
        return SpotListItem(
          spot: spot,
          animeTitle: spot.animeTitle ?? card.title,
          onTap: () => _openSpotDetail(spot),
        );
      },
    );
  }

  Spot _withComputedDistance(Spot spot) {
    if (spot.distanceM != null) return spot;
    final current = widget.currentLocation;
    final lat = spot.latitude;
    final lng = spot.longitude;
    if (current == null || lat == null || lng == null) return spot;
    final distance = _distanceMeters(
      current.latitude,
      current.longitude,
      lat,
      lng,
    );
    return Spot(
      spotId: spot.spotId,
      name: spot.name,
      animeId: spot.animeId,
      animeTitle: spot.animeTitle,
      keyVisualUrl: spot.keyVisualUrl,
      latitude: spot.latitude,
      longitude: spot.longitude,
      distanceM: distance,
      city: spot.city,
      address: spot.address,
      image: spot.image,
      streetViewUrl: spot.streetViewUrl,
      streetViewImageUrl: spot.streetViewImageUrl,
      streetViewProxyUrl: spot.streetViewProxyUrl,
      visited: _visitedSpotIds.contains(spot.spotId),
      episode: spot.episode,
    );
  }

  Widget _buildSpotListControls() {
    return Row(
      children: [
        ...List.generate(_kSpotFilters.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: AppChip(
              label: _kSpotFilters[i],
              selected: _spotFilterIndex == i,
              onTap: () => setState(() => _spotFilterIndex = i),
            ),
          );
        }),
        const Spacer(),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () =>
              setState(() => _spotSortIndex = (_spotSortIndex + 1) % 2),
          child: Row(
            children: [
              Text(
                _spotSortIndex == 0 ? '距離が近い順' : '名前順',
                style: AppTextStyles.label,
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openSpotDetail(Spot spot) async {
    final detail = _withComputedDistance(spot);
    setState(() {
      _detailSpot = detail;
      _detailPostUrls = [];
    });
    widget.onShowSpots([detail]);
    final urls = await _api.fetchSpotPostUrls(detail.spotId);
    if (!mounted || _detailSpot?.spotId != detail.spotId) return;
    setState(() => _detailPostUrls = urls);
  }

  Widget _buildSpotDetail(ScrollController controller, Spot spot) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return ListView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxl + bottomInset,
      ),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              color: AppColors.textSecondary,
              onPressed: _backToSpotList,
            ),
            Expanded(
              child: Text(
                spot.animeTitle ?? _selected?.title ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.input.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          spot.name,
          style: AppTextStyles.title.copyWith(
            fontSize: 24,
            color: const Color(0xFF12265A),
          ),
        ),
        if (spot.addressText.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  spot.addressText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle.copyWith(
                    color: const Color(0xFF12265A),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        _buildSpotDetailStats(spot),
        const SizedBox(height: AppSpacing.md),
        AppButton(label: 'ナビ開始', onPressed: () => _openNavigation(spot)),
        const SizedBox(height: AppSpacing.xxl),
        _buildPhotoGrid(spot),
        if (spot.addressText.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  spot.addressText,
                  style: AppTextStyles.subtitle.copyWith(
                    color: const Color(0xFF12265A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSpotDetailStats(Spot spot) {
    final distance = spot.distanceText.isEmpty ? '-' : spot.distanceText;
    final minutes = _estimatedMinutes(spot);
    final timeText = minutes == null ? '-' : _durationText(minutes);
    final selected = _selected;
    final stampTotal = selected == null
        ? 0
        : selected.spotCount > 0
        ? selected.spotCount
        : selected.spots.length;
    final stampCount = _visitedSpotIds.length;
    final stampText = stampTotal <= 0
        ? '$stampCount/0'
        : '$stampCount/$stampTotal';
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5FA),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatCell('現在地から', distance)),
          const SizedBox(
            height: 38,
            child: VerticalDivider(width: 1, color: AppColors.borderDefault),
          ),
          Expanded(child: _buildStatCell('予想時間', timeText)),
          const SizedBox(
            height: 38,
            child: VerticalDivider(width: 1, color: AppColors.borderDefault),
          ),
          Expanded(child: _buildStatCell('スタンプ', stampText)),
        ],
      ),
    );
  }

  Widget _buildStatCell(String label, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(value, style: AppTextStyles.subtitle.copyWith(fontSize: 18)),
      ],
    );
  }

  int? _estimatedMinutes(Spot spot) {
    final meters = spot.distanceM;
    if (meters == null) return null;
    return math.max(1, (meters / 80).round());
  }

  String _durationText(int minutes) {
    if (minutes < 60) return '$minutes分';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours時間' : '$hours時間$rest分';
  }

  Future<void> _openNavigation(Spot spot) async {
    final lat = spot.latitude;
    final lng = spot.longitude;
    if (lat == null || lng == null) return;
    final selected = _selected;
    if (selected == null) return;
    final stampTotal = selected.spotCount > 0
        ? selected.spotCount
        : selected.spots.length;
    final photos = _photoUrls(spot);
    final imageUrl = photos.isEmpty ? null : photos.first;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NavigationScreen(
          spot: spot,
          cardId: selected.cardId,
          stampCount: _visitedSpotIds.length,
          stampTotal: stampTotal,
          imageUrl: imageUrl,
          origin: widget.currentLocation,
        ),
      ),
    );
  }

  List<String> _photoUrls(Spot spot) {
    final urls = <String>[];
    final streetView = spot.streetViewProxyUrl ?? spot.streetViewImageUrl;
    if (streetView != null && streetView.isNotEmpty) urls.add(streetView);
    urls.addAll(_detailPostUrls);
    return urls;
  }

  Widget _buildPhotoGrid(Spot spot) {
    final photos = _photoUrls(spot);
    return SpotPhotoGallery(
      photoUrls: photos,
      authHeaders: _authHeaders,
      requiresAuthHeaders: (url) =>
          url == spot.streetViewProxyUrl || url == spot.streetViewImageUrl,
    );
  }

  Widget _buildScrollableState(ScrollController controller, Widget child) {
    return CustomScrollView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
    );
  }

  Widget _centerMessage(String text, {bool retry = false}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: const TextStyle(color: AppColors.textMuted)),
          if (retry) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: '再読み込み',
              onPressed: _load,
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.compact,
              fullWidth: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingAnimation(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/loading.gif',
            width: 110,
            height: 110,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
