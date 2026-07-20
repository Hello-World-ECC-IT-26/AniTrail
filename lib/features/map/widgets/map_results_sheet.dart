import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
import '../../spot/widgets/spot_comments_section.dart';
import '../models/anime_spot.dart';
import '../services/spot_api.dart';
import 'spot_list_item.dart';

const _kFilters = ['すべて', '訪問済み', '未訪問'];

enum _SheetLevel { anime, spots, detail }

/// 検索結果シート。アニメ一覧→聖地一覧→聖地詳細を1枚のシート内で切り替える。
class MapResultsSheet extends StatefulWidget {
  final List<AnimeResult> results;
  final AnimeResult? selectedAnime;
  final int filterIndex;
  final bool loading;
  final bool spotsLoading;
  final String? error;
  final int sortIndex;
  final ValueChanged<AnimeResult> onSelectAnime;
  final VoidCallback onBack;
  final ValueChanged<int> onFilterChange;
  final ValueChanged<int> onSortChange;
  final ValueChanged<Spot>? onSpotTap;
  final VoidCallback? onDetailClose;
  final ValueChanged<double>? onSheetSizeChanged;
  final LatLng? currentLocation;
  final Future<void> Function()? onArrivalRecorded;

  const MapResultsSheet({
    super.key,
    required this.results,
    required this.selectedAnime,
    required this.filterIndex,
    required this.sortIndex,
    required this.onSelectAnime,
    required this.onBack,
    required this.onFilterChange,
    required this.onSortChange,
    this.onSpotTap,
    this.onDetailClose,
    this.onSheetSizeChanged,
    this.currentLocation,
    this.onArrivalRecorded,
    this.loading = false,
    this.spotsLoading = false,
    this.error,
  });

  @override
  State<MapResultsSheet> createState() => _MapResultsSheetState();
}

class _MapResultsSheetState extends State<MapResultsSheet> {
  Spot? _detailSpot;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_onSheetChanged);
  }

  void _onSheetChanged() {
    if (_sheetController.isAttached) {
      widget.onSheetSizeChanged?.call(_sheetController.size);
    }
  }

  _SheetLevel get _level {
    if (_detailSpot != null) return _SheetLevel.detail;
    if (widget.selectedAnime != null) return _SheetLevel.spots;
    return _SheetLevel.anime;
  }

  void _openDetail(Spot spot) {
    setState(() => _detailSpot = spot);
    widget.onSpotTap?.call(spot);
  }

  void _closeDetail() {
    setState(() => _detailSpot = null);
    widget.onDetailClose?.call();
  }

  SliverToBoxAdapter _centerMessage(Widget child) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildLoadingAnimation(String message) {
    return Column(
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
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.grey,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(MapResultsSheet old) {
    super.didUpdateWidget(old);
    if (old.selectedAnime != null && widget.selectedAnime == null) {
      _detailSpot = null;
    }
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetChanged);
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.55,
      minChildSize: 0.2,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
            boxShadow: AppShadows.sheet,
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: switch (_level) {
              _SheetLevel.anime => _animeListSlivers(),
              _SheetLevel.spots => _spotListSlivers(),
              _SheetLevel.detail => _detailSlivers(),
            },
          ),
        );
      },
    );
  }

  // ── レベル0: アニメ一覧 ─────────────────────────────────────────────────────
  List<Widget> _animeListSlivers() {
    final handle = SliverToBoxAdapter(child: _buildHandle());

    if (widget.loading) {
      return [handle, _centerMessage(_buildLoadingAnimation('検索しています・・・'))];
    }
    if (widget.error != null) {
      return [
        handle,
        _centerMessage(Text(widget.error!, style: AppTextStyles.hint)),
      ];
    }
    if (widget.results.isEmpty) {
      return [
        handle,
        _centerMessage(
          const Text('該当するアニメが見つかりませんでした', style: AppTextStyles.hint),
        ),
      ];
    }

    return [
      handle,
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        sliver: SliverList.separated(
          itemCount: widget.results.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, i) {
            final anime = widget.results[i];
            final token =
                Supabase.instance.client.auth.currentSession?.accessToken;
            final headers = token != null
                ? {'Authorization': 'Bearer $token'}
                : <String, String>{};
            final baseUrl = (dotenv.env['API_BASE_URL'] ?? '').replaceAll(
              RegExp(r'/$'),
              '',
            );
            final previewUrls = anime.spotPreview
                .map((p) => p.proxyUrl(baseUrl))
                .whereType<String>()
                .toList();
            return SearchResultCard(
              title: anime.title,
              bannerImage: anime.keyVisualUrl,
              spotCount: anime.spotCount,
              spotImages: previewUrls,
              httpHeaders: headers,
              onViewSpots: () => widget.onSelectAnime(anime),
            );
          },
        ),
      ),
    ];
  }

  // ── レベル1: 聖地一覧 ───────────────────────────────────────────────────────
  List<Widget> _spotListSlivers() {
    final anime = widget.selectedAnime!;
    final spots = anime.spots.where((s) {
      switch (widget.filterIndex) {
        case 1:
          return s.visited;
        case 2:
          return !s.visited;
        default:
          return true;
      }
    }).toList();
    if (widget.sortIndex == 1) spots.sort((a, b) => a.name.compareTo(b.name));

    return [
      SliverToBoxAdapter(child: _buildHandle()),
      SliverToBoxAdapter(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              color: AppColors.textSecondary,
              onPressed: widget.onBack,
            ),
            Expanded(
              child: Text(
                anime.title,
                style: AppTextStyles.input.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              ...List.generate(_kFilters.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: AppChip(
                    label: _kFilters[i],
                    selected: widget.filterIndex == i,
                    onTap: () => widget.onFilterChange(i),
                  ),
                );
              }),
              const Spacer(),
              GestureDetector(
                onTap: () => widget.onSortChange((widget.sortIndex + 1) % 2),
                child: Row(
                  children: [
                    Text(
                      widget.sortIndex == 0 ? '距離が近い順' : '名前順',
                      style: AppTextStyles.label,
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(child: Divider(height: 1)),
      if (widget.spotsLoading)
        _centerMessage(_buildLoadingAnimation('聖地を読み込んでいます・・・'))
      else if (spots.isEmpty)
        _centerMessage(
          Text(
            widget.filterIndex == 0 ? '聖地が登録されていません' : '該当する聖地はありません',
            style: AppTextStyles.hint,
          ),
        )
      else
        SliverList.separated(
          itemCount: spots.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
          itemBuilder: (context, i) => SpotListItem(
            spot: spots[i],
            animeTitle: anime.title,
            onTap: () => _openDetail(spots[i]),
          ),
        ),
    ];
  }

  // ── レベル2: 聖地詳細 ───────────────────────────────────────────────────────
  List<Widget> _detailSlivers() {
    return [
      SliverToBoxAdapter(child: _buildHandle()),
      SliverToBoxAdapter(
        child: _SpotDetailContent(
          key: ValueKey(_detailSpot!.spotId),
          spot: _detailSpot!,
          animeTitle: widget.selectedAnime?.title ?? '',
          onBack: _closeDetail,
          currentLocation: widget.currentLocation,
          onArrivalRecorded: widget.onArrivalRecorded,
        ),
      ),
    ];
  }
}

// ── 聖地詳細の中身（StatefulWidget で bookmark 状態を持つ） ──────────────────
class _SpotDetailContent extends StatefulWidget {
  final Spot spot;
  final String animeTitle;
  final VoidCallback onBack;
  final LatLng? currentLocation;
  final Future<void> Function()? onArrivalRecorded;

  const _SpotDetailContent({
    super.key,
    required this.spot,
    required this.animeTitle,
    required this.onBack,
    this.currentLocation,
    this.onArrivalRecorded,
  });

  @override
  State<_SpotDetailContent> createState() => _SpotDetailContentState();
}

class _SpotDetailContentState extends State<_SpotDetailContent> {
  final SpotApi _api = SpotApi();
  bool _bookmarked = false;
  bool _bookmarkLoading = true;
  List<String> _postUrls = [];
  bool _openingNavigation = false;

  Spot get spot => widget.spot;

  Map<String, String> get _authHeaders {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return token != null ? {'Authorization': 'Bearer $token'} : {};
  }

  @override
  void initState() {
    super.initState();
    _loadBookmark();
    _loadPostUrls();
  }

  @override
  void didUpdateWidget(_SpotDetailContent old) {
    super.didUpdateWidget(old);
    if (old.spot.spotId != widget.spot.spotId) {
      setState(() {
        _bookmarkLoading = true;
        _postUrls = [];
      });
      _loadBookmark();
      _loadPostUrls();
    }
  }

  Future<void> _loadPostUrls() async {
    final urls = await _api.fetchSpotPostUrls(spot.spotId);
    if (mounted) setState(() => _postUrls = urls);
  }

  Future<void> _loadBookmark() async {
    try {
      final result = await _api.isBookmarked(spot.spotId);
      if (mounted) {
        setState(() {
          _bookmarked = result;
          _bookmarkLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _bookmarkLoading = false);
    }
  }

  Future<void> _toggleBookmark() async {
    setState(() => _bookmarkLoading = true);
    try {
      if (_bookmarked) {
        await _api.removeBookmark(spot.spotId);
      } else {
        await _api.addBookmark(spot.spotId);
      }
      if (mounted) {
        setState(() {
          _bookmarked = !_bookmarked;
          _bookmarkLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _bookmarkLoading = false);
    }
  }

  Future<void> _openDirections() async {
    if (_openingNavigation) return;
    final lat = spot.latitude;
    final lng = spot.longitude;
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('目的地の位置情報がありません')));
      return;
    }
    setState(() => _openingNavigation = true);
    try {
      final collections = await _api.fetchStampCollections(force: true);
      final collection = collections
          .where(
            (item) => item.card.spots.any(
              (candidate) => candidate.spotId == spot.spotId,
            ),
          )
          .firstOrNull;
      if (collection == null) {
        throw StateError('この聖地を含むしおりがありません。先にしおりへ追加してください');
      }
      if (!mounted) return;
      final acquired = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => NavigationScreen(
            spot: spot,
            cardId: collection.card.cardId,
            stampCount: collection.visitStats.length,
            stampTotal: collection.card.spotCount > 0
                ? collection.card.spotCount
                : collection.card.spots.length,
            imageUrl: _streetViewUrl,
            origin: widget.currentLocation,
          ),
        ),
      );
      if (acquired == true && mounted) {
        widget.onBack();
        await widget.onArrivalRecorded?.call();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ナビを開始できませんでした: $error')));
    } finally {
      if (mounted) setState(() => _openingNavigation = false);
    }
  }

  String? get _streetViewUrl =>
      spot.streetViewProxyUrl ?? spot.streetViewImageUrl;

  // Street View を先頭固定、続いてユーザー投稿写真
  List<String> get _photoUrls {
    final urls = <String>[];
    final sv = _streetViewUrl;
    if (sv != null && sv.isNotEmpty) urls.add(sv);
    urls.addAll(_postUrls);
    return urls;
  }

  Widget _imageWidget(String url) {
    final isProxy =
        url == spot.streetViewProxyUrl || url == spot.streetViewImageUrl;
    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: isProxy ? _authHeaders : {},
      fit: BoxFit.cover,
      placeholder: (_, _) => _placeholder(),
      errorWidget: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
    color: AppColors.grey,
    child: const Icon(Icons.image, color: AppColors.textHint, size: 32),
  );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 戻るボタン行
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              color: AppColors.textSecondary,
              onPressed: widget.onBack,
            ),
            Expanded(
              child: Text(
                widget.animeTitle,
                style: AppTextStyles.input.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // スポット名 + ブックマーク
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(spot.name, style: AppTextStyles.title),
                    if (spot.distanceText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '現在地から ${spot.distanceText}',
                        style: AppTextStyles.label,
                      ),
                    ],
                    if (spot.addressText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              spot.addressText,
                              style: AppTextStyles.label,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _bookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: AppColors.primary,
                ),
                onPressed: _bookmarkLoading ? null : _toggleBookmark,
              ),
            ],
          ),
        ),

        // 経路ボタン
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: AppButton(
            label: _openingNavigation ? 'しおりを確認中・・・' : 'ナビ開始',
            onPressed: _openingNavigation ? null : _openDirections,
          ),
        ),

        // 写真グリッド
        if (_photoUrls.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _buildPhotoGrid(),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SpotCommentsSection(spotId: spot.spotId),
        ),

        SizedBox(height: 24 + bottomInset),
      ],
    );
  }

  Widget _buildPhotoGrid() {
    final photos = _photoUrls;

    if (photos.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(aspectRatio: 4 / 3, child: _imageWidget(photos[0])),
      );
    }

    if (photos.length == 2) {
      return SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
                child: _imageWidget(photos[0]),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                child: _imageWidget(photos[1]),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              child: _imageWidget(photos[0]),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(10),
                    ),
                    child: _imageWidget(photos[1]),
                  ),
                ),
                const SizedBox(height: 3),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(10),
                    ),
                    child: _imageWidget(photos[2]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
