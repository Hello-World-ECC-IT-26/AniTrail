import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/styles/app_styles.dart';

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

  const SearchResultCard({
    super.key,
    required this.title,
    this.bannerImage,
    this.spotCount = 10,
    this.spotImages = const [],
    this.httpHeaders = const {},
    this.onViewSpots,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                ..._buildSpotThumbnails(),
                const Spacer(),
                ElevatedButton(
                  onPressed: onViewSpots,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '聖地を見る',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
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
                        Container(color: Colors.grey.shade200),
                    errorWidget: (_, _, _) => _placeholderBanner(),
                  )
                : _placeholderBanner(),
          ),
          // グラデーションオーバーレイ
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: [0, 0.55, 1],
                  colors: [
                    Color(0xB34A76E8),
                    Color(0x80745FC6),
                    Color(0x33745FC6),
                  ],
                ),
              ),
            ),
          ),
          // アニメタイトル（左下）
          Positioned(
            left: 12,
            right: 12,
            bottom: 28,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
              ),
            ),
          ),
          // 聖地数（左下）
          Positioned(
            left: 12,
            bottom: 10,
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Colors.white70,
                  size: 14,
                ),
                const SizedBox(width: 3),
                Text(
                  '聖地 $spotCount箇所',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderBanner() {
    return Container(
      color: Colors.grey.shade300,
      child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 40),
    );
  }

  List<Widget> _buildSpotThumbnails() {
    const maxCount = 4;

    return List.generate(maxCount, (index) {
      final url = index < spotImages.length ? spotImages[index] : null;

      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 44,
            height: 44,
            child: url != null
                ? CachedNetworkImage(
                    imageUrl: url,
                    httpHeaders: httpHeaders,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: Colors.grey.shade200),
                    errorWidget: (_, _, _) =>
                        Container(color: Colors.grey.shade300),
                  )
                : Container(color: Colors.grey.shade300),
          ),
        ),
      );
    });
  }
}
