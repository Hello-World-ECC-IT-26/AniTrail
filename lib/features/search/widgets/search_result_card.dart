import 'package:flutter/material.dart';
import '../../../core/styles/app_styles.dart';

class SearchResultCard extends StatelessWidget {
  final String title;
  final String? bannerImage;
  final int spotCount;

  /// 聖地のサムネイル画像リスト（最大4枚）
  final List<String> spotImages;

  /// 「聖地を見る」ボタンタップ時のコールバック
  final VoidCallback? onViewSpots;

  const SearchResultCard({
    super.key,
    required this.title,
    this.bannerImage,
    this.spotCount = 10,
    this.spotImages = const [],
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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── バナー画像（上部・タイトルオーバーレイ付き） ──
          _buildBanner(),

          // ── 下部エリア（スタンプ + ボタン） ────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                // スタンプサムネイル（最大4枚）
                ..._buildSpotThumbnails(),

                const Spacer(),

                // 聖地を見るボタン
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

  // ── バナー画像（タイトル・聖地数オーバーレイ付き） ──────
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
                ? Image.asset(bannerImage!, fit: BoxFit.cover)
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/place_sample.jpg',
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.8),
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade300,
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.grey.shade400,
                            size: 40,
                          ),
                        ),
                      ),

                      // Overlay
                      Container(color: Colors.white.withValues(alpha: 0.2)),
                    ],
                  ),
          ),

          // グラデーションオーバーレイ
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
          ),

          // アニメタイトル（左下）
          Positioned(
            left: 12,
            bottom: 28,
            child: Text(
              title,
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

  // ── スタンプサムネイル（最大4枚） ──────────────────────
  List<Widget> _buildSpotThumbnails() {
    const maxCount = 4;

    return List.generate(maxCount, (index) {
      final hasImage = index < spotImages.length;

      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 44,
            height: 44,
            child: hasImage
                ? Image.asset(
                    spotImages[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        //// 画像読み込み失敗時の背景
                        Container(color: Colors.grey.shade300),
                  )
                // 画像がない場合のグレー背景
                : Container(color: Colors.grey.shade300),
          ),
        ),
      );
    });
  }
}
