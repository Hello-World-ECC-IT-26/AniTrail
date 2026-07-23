import 'package:anitrail/features/home/screens/home_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/widgets/loading_screen.dart';
import '../../../core/styles/app_dimens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/main_buttom_nav.dart';
import '../../map/models/anime_spot.dart';
import '../../map/services/spot_api.dart';
import '../../shiori/models/shiori_draft.dart';
import '../../shiori/screens/shiori_list.dart';
import 'spot_detail.dart';

class SpotList extends StatefulWidget {
  final String animeId;
  final String animeTitle;

  /// アニメのキービジュアルURL（バナー・network画像）
  final String? bannerImageUrl;
  final int spotCount;

  const SpotList({
    super.key,
    required this.animeId,
    required this.animeTitle,
    this.bannerImageUrl,
    this.spotCount = 10,
  });

  @override
  State<SpotList> createState() => _SpotListState();
}

class _SpotListState extends State<SpotList> {
  final SpotApi _api = SpotApi();

  final ShioriDraft _draft = ShioriDraft.instance;

  List<Spot> _spots = [];
  bool _loading = true;
  String? _error;

  // ブックマーク済みの聖地（spot_id）
  final Set<String> _bookmarked = {};

  Map<String, String> get _authHeaders {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return token != null ? {'Authorization': 'Bearer $token'} : {};
  }

  @override
  void initState() {
    super.initState();
    _loadSpots();
    _draft.spots.addListener(_onDraftChanged);
  }

  @override
  void dispose() {
    _draft.spots.removeListener(_onDraftChanged);
    super.dispose();
  }

  void _onDraftChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSpots() async {
    try {
      final spots = await _api.fetchSpots(widget.animeId);
      if (!mounted) return;
      setState(() {
        _spots = spots
            .map(
              (spot) => spot.withAnime(
                animeId: widget.animeId,
                animeTitle: widget.animeTitle,
                keyVisualUrl: widget.bannerImageUrl,
              ),
            )
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '聖地の取得に失敗しました。';
      });
    }
  }

  void _toggleSelect(Spot spot) {
    _draft.toggle(spot); // リスナー経由で再描画
  }

  void _openDetail(Spot spot) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SpotDetailScreen(
          spot: spot,
          animeTitle: widget.animeTitle,
          keyVisualUrl: widget.bannerImageUrl,
        ),
      ),
    );
  }

  Future<void> _toggleBookmark(String spotId) async {
    final wasBookmarked = _bookmarked.contains(spotId);
    setState(() {
      wasBookmarked ? _bookmarked.remove(spotId) : _bookmarked.add(spotId);
    });
    try {
      if (wasBookmarked) {
        await _api.removeBookmark(spotId);
      } else {
        await _api.addBookmark(spotId);
      }
    } catch (_) {
      // 失敗したら元に戻す
      if (!mounted) return;
      setState(() {
        wasBookmarked ? _bookmarked.add(spotId) : _bookmarked.remove(spotId);
      });
    }
  }

  void _createShiori() {
    final selected = List<Spot>.from(_draft.spots.value);
    if (selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('聖地を「+追加」してから作成してください')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ShioriListScreen(spots: selected)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              if (_loading)
                const SliverFillRemaining(
                  child: AppLoadingScreen(message: '聖地を読み込んでいます・・・'),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              else if (_spots.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      '聖地が登録されていません',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    120,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _buildSpotCard(_spots[index]),
                      ),
                      childCount: _spots.length,
                    ),
                  ),
                ),
            ],
          ),

          // ── 旅のしおりを作成ボタン（左下固定） ─────
          Positioned(
            left: AppSpacing.lg,
            bottom: AppSpacing.sm,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AppButton(
                  label: '旅のしおりを作成',
                  icon: Icons.location_on_outlined,
                  size: AppButtonSize.compact,
                  fullWidth: false,
                  backgroundColor: AppColors.tabiShiori,
                  onPressed: _createShiori,
                ),

                // バッジ（選択数）
                if (_draft.spots.value.isNotEmpty)
                  Positioned(
                    top: -AppSpacing.xs,
                    right: -AppSpacing.xs,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.badge,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${_draft.spots.value.length}',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: MainBottomNav(
        onTap: (index) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        },
      ),
    );
  }

  // ── アニメバナーヘッダー ────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Stack(
              fit: StackFit.expand,
              children: [
                widget.bannerImageUrl != null &&
                        widget.bannerImageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.bannerImageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, imageUrl, error) =>
                            _bannerPlaceholder(),
                      )
                    : _bannerPlaceholder(),
                const DecoratedBox(
                  decoration: BoxDecoration(gradient: AppColors.cardGradient),
                ),
              ],
            ),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.animeTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                      shadows: [Shadow(color: AppColors.black)],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.white,
                        size: 14,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '聖地 ${widget.spotCount}箇所',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bannerPlaceholder() => Container(
    color: AppColors.primary,
    child: Icon(
      Icons.movie_outlined,
      color: AppColors.white.withValues(alpha: 0.54),
      size: 56,
    ),
  );

  // ── 聖地サムネイル（実写真→Street View→プレースホルダ） ──
  Widget _buildThumbnail(Spot spot) {
    final image = spot.image;
    if (image != null && image.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: image,
        fit: BoxFit.cover,
        placeholder: (context, imageUrl) => _placeholderImage(),
        errorWidget: (context, imageUrl, error) =>
            _streetViewOrPlaceholder(spot),
      );
    }
    return _streetViewOrPlaceholder(spot);
  }

  Widget _streetViewOrPlaceholder(Spot spot) {
    final url = spot.streetViewProxyUrl ?? spot.streetViewImageUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        httpHeaders: _authHeaders,
        fit: BoxFit.cover,
        placeholder: (context, imageUrl) => _placeholderImage(),
        errorWidget: (context, imageUrl, error) => _placeholderImage(),
      );
    }
    return _placeholderImage();
  }

  Widget _placeholderImage() => Container(
    color: AppColors.placeholder,
    child: const Icon(Icons.image_outlined, color: AppColors.iconMuted),
  );

  // ── 聖地カード1枚 ───────────────────────────────────
  Widget _buildSpotCard(Spot spot) {
    final isBookmarked = _bookmarked.contains(spot.spotId);
    final isSelected = _draft.contains(spot.spotId);

    return AppCard(
      clip: true,
      child: Row(
        children: [
          // ── サムネイル + ブックマーク ──────────────
          Stack(
            children: [
              SizedBox(width: 150, height: 130, child: _buildThumbnail(spot)),
              Positioned(
                top: AppSpacing.xs,
                left: AppSpacing.xs,
                child: AppCircleIconButton(
                  icon: isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                  onTap: () => _toggleBookmark(spot.spotId),
                  size: 28,
                  iconSize: 16,
                ),
              ),
            ],
          ),

          // ── テキスト情報 ──────────────────────────
          Expanded(
            child: SizedBox(
              height: 130,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Anime + 追加
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            spot.animeTitle ?? widget.animeTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.label.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),

                        TextButton.icon(
                          onPressed: () => _toggleSelect(spot),
                          icon: Icon(
                            isSelected ? Icons.check : Icons.add,
                            size: 14,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                          label: Text(
                            isSelected ? '追加済み' : '追加',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    // 場所名
                    Text(
                      spot.name,
                      style: AppTextStyles.subtitle,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    // 住所
                    Text(
                      spot.addressText,
                      style: AppTextStyles.label.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // 詳細（右下）
                    Align(
                      alignment: Alignment.bottomRight,
                      child: AppButton(
                        label: '詳細',
                        onPressed: () => _openDetail(spot),
                        size: AppButtonSize.compact,
                        fullWidth: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
