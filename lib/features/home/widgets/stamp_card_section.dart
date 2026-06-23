import 'package:flutter/material.dart';
import '../../../core/styles/app_styles.dart';
import '../../shiori/widgets/shiori_detail.dart';

class StampCardSection extends StatefulWidget {
  final List<Map<String, String>> cards;
  const StampCardSection({super.key, required this.cards});

  @override
  State<StampCardSection> createState() => _StampCardSectionState();
}

class _StampCardSectionState extends State<StampCardSection> {
  // 開いているカードのindex（nullなら全部閉じ）
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // セクションタイトル
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '作成日順',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down, size: 16),
                  ],
                ),
              ),

              const Expanded(
                child: Center(
                  child: Text(
                    '作成した旅のしおり',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  '作成',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(foregroundColor: Colors.black87),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // カードリスト（デッキ風に重なって表示）
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // カード1枚の高さ
              const double cardHeight = 130;
              // 閉じているカードが下から見える幅
              const double peekHeight = 100.0;
              // 展開中のカードの追加高さ（サムネイル + ボタン）
              const double expandedExtra = 120.0;

              // Stack全体の高さを計算
              final expandedIndex = _expandedIndex;
              double totalHeight =
                  cardHeight +
                  (widget.cards.length - 1) * peekHeight +
                  (expandedIndex != null ? expandedExtra : 0);

              return SizedBox(
                height: totalHeight,
                child: Stack(
                  children: List.generate(widget.cards.length, (index) {
                    final card = widget.cards[index];
                    final isExpanded = _expandedIndex == index;

                    // 展開中カードより後ろのカードは下にずらす
                    double topOffset = index * peekHeight;
                    if (expandedIndex != null && index > expandedIndex) {
                      topOffset += expandedExtra;
                    }

                    return Positioned(
                      top: topOffset,
                      left: 0,
                      right: 0,
                      child: _ShioriCard(
                        title: card['title']!,
                        spotCount:
                            int.tryParse(card['spotCount'] ?? '10') ?? 10,
                        bannerImage: card['bannerImage'],
                        isExpanded: isExpanded,
                        spotImages: const [],
                        onTap: () {
                          setState(() {
                            _expandedIndex = isExpanded ? null : index;
                          });
                        },
                        onViewDetail: () {
                          // しおり詳細画面へ遷移
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ShioriDetailScreen(),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

/// 個別しおりカード（アコーディオン）
class _ShioriCard extends StatelessWidget {
  final String title;
  final int spotCount;
  final String? bannerImage;
  final bool isExpanded;
  final List<String> spotImages;
  final VoidCallback onTap;
  final VoidCallback onViewDetail;

  const _ShioriCard({
    required this.title,
    required this.spotCount,
    this.bannerImage,
    required this.isExpanded,
    required this.spotImages,
    required this.onTap,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          children: [
            // ── バナー部分（常に表示） ────────────────
            _buildBanner(),

            // ── 展開時: サムネイル + 詳細ボタン ────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 280),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: _buildExpandedContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ── バナー（画像 + タイトル + 聖地数 + 矢印） ──────────
  Widget _buildBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
        bottomLeft: Radius.circular(isExpanded ? 0 : 16),
        bottomRight: Radius.circular(isExpanded ? 0 : 16),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 130,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // バナー画像
            bannerImage != null
                ? Image.asset(bannerImage!, fit: BoxFit.cover)
                : Image.asset(
                    'assets/images/place_sample.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.center, // 画像の中央を表示
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppColors.primary),
                  ),

            // グラデーションオーバーレイ
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),

            // タイトルと聖地数（左側）
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white70,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '聖地 $spotCount箇所',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 矢印アイコン（右上）
            Positioned(
              top: 10,
              right: 12,
              child: AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 280),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 展開コンテンツ（サムネイル + 詳細ボタン） ───────────
  Widget _buildExpandedContent() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          // スポットサムネイル（最大4枚）
          ...List.generate(4, (index) {
            final hasImage = index < spotImages.length;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: hasImage
                      ? Image.asset(
                          spotImages[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.grey.shade300),
                        )
                      : Container(color: Colors.grey.shade300),
                ),
              ),
            );
          }),

          const Spacer(),

          // 詳細を見るボタン
          ElevatedButton(
            onPressed: onViewDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              '詳細を見る',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
