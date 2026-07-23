import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/styles/app_dimens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/main_buttom_nav.dart';
import '../../../core/widgets/app_bar.dart';
import '../../home/screens/home_screen.dart';
import '../../map/models/anime_spot.dart';
import '../../map/services/spot_api.dart';

class ShioriCompleteScreen extends StatefulWidget {
  /// 作成したしおりのID（stamp_cards.card_id）
  final String cardId;

  /// 作成したしおりのタイトル
  final String shioriTitle;

  /// しおりに追加した聖地リスト
  final List<Spot> spots;

  const ShioriCompleteScreen({
    super.key,
    required this.cardId,
    this.shioriTitle = 'しおりタイトル',
    this.spots = const [],
  });

  @override
  State<ShioriCompleteScreen> createState() => _ShioriCompleteScreenState();
}

class _ShioriCompleteScreenState extends State<ShioriCompleteScreen> {
  final SpotApi _api = SpotApi();
  Set<String> _visited = {};

  Map<String, String> get _authHeaders {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return token != null ? {'Authorization': 'Bearer $token'} : {};
  }

  @override
  void initState() {
    super.initState();
    _loadStamps();
  }

  Future<void> _loadStamps() async {
    final visited = await _api.fetchVisitedSpotIds(widget.cardId);
    if (mounted) setState(() => _visited = visited);
  }

  @override
  Widget build(BuildContext context) {
    final spots = widget.spots;
    final total = spots.length;
    final obtained = spots.where((s) => _visited.contains(s.spotId)).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AniTrailAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.lg,
          40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '旅のしおりが作成されました！',
                style: AppTextStyles.successMessage,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            if (_animeVisualSpots.isNotEmpty) ...[
              _buildAnimeVisuals(),
              const SizedBox(height: AppSpacing.xl),
            ],

            // ── しおりカード ──────────────────────────
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── ヘッダー（タイトル + 編集・削除） ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.shioriTitle,
                          style: AppTextStyles.subtitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 編集ボタン（スコープ外・準備中）
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('編集は準備中です')),
                          );
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        label: Text(
                          '編集',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
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
                  const SizedBox(height: AppSpacing.md),

                  // ── 聖地リスト ──────────────────────
                  ...spots.map((spot) => _buildSpotRow(spot)),

                  const SizedBox(height: AppSpacing.xl),

                  // ── スタンプカード ──────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'スタンプカード',
                        style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                      ),
                      Text(
                        '$obtained/$total',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // スタンプグリッド（聖地数ぶん。取得済みを着色）
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 1,
                        ),
                    itemCount: total == 0 ? 10 : total,
                    itemBuilder: (_, i) {
                      final filled = i < obtained;
                      return Container(
                        decoration: BoxDecoration(
                          color: filled ? AppColors.primary : AppColors.divider,
                          borderRadius: AppRadius.brSm,
                        ),
                        child: filled
                            ? const Icon(
                                Icons.check,
                                color: AppColors.white,
                                size: 18,
                              )
                            : null,
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            Center(
              child: Text(
                '聖地を巡ってスタンプをゲットしましょう！',
                style: AppTextStyles.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── マップで確認ボタン（スコープ外・準備中） ──
            Center(
              child: AppButton(
                label: 'マップで確認',
                icon: Icons.location_on_outlined,
                fullWidth: false,
                height: 36,
                dense: true,
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('マップ確認は準備中です')));
                },
              ),
            ),
          ],
        ),
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

  List<Spot> get _animeVisualSpots {
    final unique = <String, Spot>{};
    for (final spot in widget.spots) {
      final animeId = spot.animeId;
      final key = animeId != null && animeId.isNotEmpty
          ? animeId
          : spot.animeTitle ?? '';
      if (key.isNotEmpty) unique.putIfAbsent(key, () => spot);
    }
    return unique.values.toList();
  }

  Widget _buildAnimeVisuals() {
    final animeVisualSpots = _animeVisualSpots;

    if (animeVisualSpots.length == 1) {
      return SizedBox(
        height: 160,
        child: Center(child: _buildAnimeVisual(animeVisualSpots.single)),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: animeVisualSpots.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, index) => _buildAnimeVisual(animeVisualSpots[index]),
      ),
    );
  }

  Widget _buildAnimeVisual(Spot spot) {
    return SizedBox(
      width: 360,
      child: ClipRRect(
        borderRadius: AppRadius.brMd,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (spot.keyVisualUrl != null && spot.keyVisualUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: spot.keyVisualUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _placeholderImage(),
              )
            else
              _placeholderImage(),
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.cardGradientSoft),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Text(
                spot.animeTitle ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.subtitle.copyWith(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 聖地の1行表示 ────────────────────────────────
  Widget _buildSpotRow(Spot spot) {
    final visited = _visited.contains(spot.spotId);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        clip: true,
        radius: AppRadius.md,
        child: Row(
          children: [
            SizedBox(width: 120, height: 100, child: _buildThumbnail(spot)),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Transform.translate(
                  offset: const Offset(0, -10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: spot.animeTitle?.isNotEmpty ?? false
                                ? Text(
                                    spot.animeTitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                    ),
                                  )
                                : const SizedBox(),
                          ),

                          Text(
                            visited ? '訪問済み' : '未訪問',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: visited
                                  ? AppColors.textMuted
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      Text(
                        spot.name,
                        style: AppTextStyles.subtitle,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      Text(
                        spot.addressText,
                        style: AppTextStyles.label.copyWith(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
