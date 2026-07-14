import 'package:anitrail/features/home/screens/home_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_shadows.dart';
import '../../../core/styles/app_input.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_bottom_action_bar.dart';
import '../../../core/widgets/main_buttom_nav.dart';
import '../../../core/widgets/app_bar.dart';
import '../../map/models/anime_spot.dart';
import '../../spot/screens/spot_detail.dart';
import '../widgets/loading.dart';

class ShioriListScreen extends StatefulWidget {
  /// 追加済み聖地リスト（spot_listから受け取る）
  final List<Spot> spots;

  const ShioriListScreen({super.key, this.spots = const []});

  @override
  State<ShioriListScreen> createState() => _ShioriListScreenState();
}

class _ShioriListScreenState extends State<ShioriListScreen> {
  // 編集可能な聖地リスト
  late List<Spot> _spots;
  final TextEditingController _titleController = TextEditingController();

  Map<String, String> get _authHeaders {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return token != null ? {'Authorization': 'Bearer $token'} : {};
  }

  @override
  void initState() {
    super.initState();
    _spots = List.from(widget.spots);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _deleteSpot(int index) {
    setState(() => _spots.removeAt(index));
  }

  void _openDetail(Spot spot) {
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

  void _create() {
    if (_spots.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('聖地が1つもありません')));
      return;
    }
    final title = _titleController.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatingShioriScreen(
          title: title.isEmpty ? null : title,
          spots: List.from(_spots),
          spotIds: _spots.map((s) => s.spotId).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AniTrailAppBar(),
      body: Stack(
        children: [
          // ── HEADER (back button custom) ──
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: AppSpacing.sm,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Center(child: Text('旅のしおり', style: AppTextStyles.heading)),
                ],
              ),
            ),
          ),

          // ── LIST CONTENT ──
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                120,
              ),
              children: [
                // ── しおりタイトル入力 ───────────────
                TextField(
                  controller: _titleController,
                  style: AppTextStyles.input,
                  decoration: AppInputDecorations.filled(
                    hintText: 'しおりタイトル（任意）',
                    prefixIcon: Icons.edit_outlined,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                if (_animeVisualSpots.isNotEmpty) ...[
                  _buildAnimeVisuals(),
                  const SizedBox(height: AppSpacing.lg),
                ],

                ...List.generate(_spots.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _buildSpotCard(index),
                  );
                }),

                const SizedBox(height: AppSpacing.sm),

                // ── 行き先を追加ボタン ────────────────
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 130,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.brMd,
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: AppShadows.subtle,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add,
                          color: AppColors.iconMuted,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '行き先を追加',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── BOTTOM BUTTON ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AppBottomActionBar(
              label: 'この内容で旅のしおりを作成する',
              onPressed: _create,
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
    for (final spot in _spots) {
      final animeId = spot.animeId;
      final key = animeId != null && animeId.isNotEmpty
          ? animeId
          : spot.animeTitle ?? '';
      if (key.isNotEmpty) unique.putIfAbsent(key, () => spot);
    }
    return unique.values.toList();
  }

  Widget _buildAnimeVisuals() => SizedBox(
    height: 140,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _animeVisualSpots.length,
      separatorBuilder: (context, index) =>
          const SizedBox(width: AppSpacing.sm),
      itemBuilder: (context, index) {
        final spot = _animeVisualSpots[index];
        return SizedBox(
          width: 240,
          child: ClipRRect(
            borderRadius: AppRadius.brMd,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (spot.keyVisualUrl != null && spot.keyVisualUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: spot.keyVisualUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (context, imageUrl, error) =>
                        _placeholderImage(),
                  )
                else
                  _placeholderImage(),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradientSoft,
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: Text(
                    spot.animeTitle ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  // ── 聖地カード ────────────────────────────────────
  Widget _buildSpotCard(int index) {
    final spot = _spots[index];

    return AppCard(
      clip: true,
      child: Row(
        children: [
          SizedBox(width: 150, height: 130, child: _buildThumbnail(spot)),

          // ── テキスト情報 ──────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (spot.animeTitle?.isNotEmpty ?? false)
                    Text(
                      spot.animeTitle!,
                      maxLines: 1,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: AppSpacing.xs),
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
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _deleteSpot(index),
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 14,
                          color: AppColors.error,
                        ),
                        label: const Text(
                          '削除',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          minimumSize: const Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppButton(
                        label: '詳細',
                        onPressed: () => _openDetail(spot),
                        size: AppButtonSize.compact,
                        fullWidth: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
