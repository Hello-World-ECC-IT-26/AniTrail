import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_dimens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';

class SearchResultCard extends StatelessWidget {
  final String title;

  /// アニメのキービジュアル URL（横画像）。null の場合はプレースホルダー表示
  final String? bannerImage;
  final int spotCount;

  /// 聖地のサムネイル画像 URL リスト（最大4枚）
  final List<String> spotImages;

  /// 画像リクエストに付与する HTTP ヘッダ（認証など）
  final Map<String, String> httpHeaders;

  /// 「聖地を見る」ボタンタップ時のコールバック
  final VoidCallback? onViewSpots;
  final String actionLabel;
  final int thumbnailCount;
  final bool variableSpotImages;
  final GestureDragUpdateCallback? onBannerVerticalDragUpdate;

  const SearchResultCard({
    super.key,
    required this.title,
    this.bannerImage,
    this.spotCount = 10,
    this.spotImages = const [],
    this.httpHeaders = const {},
    this.onViewSpots,
    this.actionLabel = '聖地を見る',
    this.thumbnailCount = 4,
    this.variableSpotImages = false,
    this.onBannerVerticalDragUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                ..._buildSpotThumbnails(),
                const Spacer(),
                AppButton(
                  label: actionLabel,
                  onPressed: onViewSpots,
                  size: AppButtonSize.compact,
                  fullWidth: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: onBannerVerticalDragUpdate,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.lg),
          topRight: Radius.circular(AppRadius.lg),
        ),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: 140,
              child: bannerImage != null
                  ? CachedNetworkImage(
                      imageUrl: bannerImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 140,
                      placeholder: (_, _) =>
                          Container(color: AppColors.placeholder),
                      errorWidget: (_, _, _) => _placeholderBanner(),
                    )
                  : _placeholderBanner(),
            ),
            // グラデーションオーバーレイ
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.cardGradient),
              ),
            ),
            // アニメタイトル（左下）
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: 28,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
            ),
            // 聖地数（左下）
            Positioned(
              left: AppSpacing.md,
              bottom: AppSpacing.sm,
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '聖地 $spotCount箇所',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderBanner() {
    return Container(
      color: AppColors.divider,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.iconMuted,
        size: 40,
      ),
    );
  }

  List<Widget> _buildSpotThumbnails() {
    final count = variableSpotImages
        ? spotImages.take(thumbnailCount).length
        : thumbnailCount;

    return List.generate(count, (index) {
      final url = index < spotImages.length ? spotImages[index] : null;

      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xs),
        child: ClipRRect(
          borderRadius: AppRadius.brSm,
          child: SizedBox(
            width: 44,
            height: 44,
            child: url != null
                ? CachedNetworkImage(
                    imageUrl: url,
                    httpHeaders: httpHeaders,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: AppColors.placeholder),
                    errorWidget: (_, _, _) =>
                        Container(color: AppColors.divider),
                  )
                : Container(color: AppColors.divider),
          ),
        ),
      );
    });
  }
}
