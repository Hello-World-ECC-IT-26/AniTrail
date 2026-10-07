import 'dart:math' as math;

import 'package:anitrail/features/home/screens/home_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/widgets/loading_screen.dart';
import '../../../core/styles/app_dimens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../widgets/spot_list_card.dart';
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

  /// 任意のAPIクライアント。未指定時は通常の聖地APIを使用する。
  final SpotApi? api;

  const SpotList({
    super.key,
    required this.animeId,
    required this.animeTitle,
    this.bannerImageUrl,
    this.spotCount = 10,
    this.api,
  });

  @override
  State<SpotList> createState() => _SpotListState();
}

class _SpotListState extends State<SpotList> {
  late final SpotApi _api = widget.api ?? SpotApi();

  final ShioriDraft _draft = ShioriDraft.instance;

  List<Spot> _spots = [];
  bool _loading = true;
  String? _error;

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
    final actionText = TextPainter(
      text: TextSpan(
        text: '旅のしおりを作成',
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.merge(AppTextStyles.button),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: math.max(1, MediaQuery.sizeOf(context).width - 82));
    final actionHeight = math.max(
      AppSizes.minTapTarget,
      actionText.height + 24,
    );
    actionText.dispose();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(
                    '聖地一覧',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
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
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    actionHeight + 76,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
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
            right: AppSpacing.lg,
            bottom: AppSpacing.sm,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AppButton(
                    label: '旅のしおりを作成',
                    icon: Icons.location_on_outlined,
                    height: actionHeight,
                    wrapLabel: true,
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
          ),
        ],
      ),

      bottomNavigationBar: MainBottomNav(
        itemColor: AppColors.textPrimary,
        elevation: 0,
        onTap: (index) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: index)),
          );
        },
      ),
    );
  }

  // ── アニメバナーヘッダー ────────────────────────────
  Widget _buildSliverAppBar() {
    final scaler = MediaQuery.textScalerOf(context);
    final textWidth = math.max(1.0, MediaQuery.sizeOf(context).width - 144);
    const titleStyle = TextStyle(
      fontSize: 30,
      height: 1.2,
      fontWeight: FontWeight.bold,
      color: AppColors.white,
    );
    const countStyle = TextStyle(fontSize: 12, color: AppColors.white);
    double measure(String text, TextStyle style, double width, int? maxLines) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: Theme.of(context).textTheme.bodyMedium?.merge(style),
        ),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: maxLines,
      )..layout(maxWidth: width);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final bannerHeight = math.max(
      168.0,
      measure(widget.animeTitle, titleStyle, textWidth, 3) +
          measure(
            '聖地 ${widget.spotCount}箇所',
            countStyle,
            math.max(1, textWidth - 18),
            null,
          ) +
          AppSpacing.xs +
          AppSpacing.xl +
          AppSpacing.xxl,
    );
    return SliverToBoxAdapter(
      child: SizedBox(
        height: MediaQuery.paddingOf(context).top + bannerHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.bannerImageUrl != null &&
                widget.bannerImageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: widget.bannerImageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _bannerPlaceholder(),
              )
            else
              _bannerPlaceholder(),
            const ColoredBox(color: AppColors.spotListOverlay),
            Positioned(
              left: AppSpacing.xxl,
              right: AppSpacing.xxl,
              bottom: AppSpacing.xl,
              child: Row(
                children: [
                  IconButton(
                    tooltip: '戻る',
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.animeTitle,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 30,
                            height: 1.2,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
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
                            Flexible(
                              child: Text(
                                '聖地 ${widget.spotCount}箇所',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
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
  Widget _buildSpotCard(Spot spot) => SpotListCard(
    spot: spot,
    animeTitle: widget.animeTitle,
    thumbnail: _buildThumbnail(spot),
    selected: _draft.contains(spot.spotId),
    onAdd: () => _toggleSelect(spot),
    onOpen: () => _openDetail(spot),
  );
}
