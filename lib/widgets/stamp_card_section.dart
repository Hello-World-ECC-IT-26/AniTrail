import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Text(
            '作成したスタンプカード',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),

        const SizedBox(height: 10),
        // カードリスト
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: widget.cards.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final card = widget.cards[index];
            final isExpanded = _expandedIndex == index;

            // インデックスに応じて青の濃さを変える
            final colors = [
              const Color(0xFFDCEEFD),
              const Color(0xFFB3D9F8),
              const Color(0xFF89C4F4),
              const Color(0xFF5AAEE8),
              const Color(0xFF2196F3),
            ];
            final bgColor = colors[index % colors.length];
            final isDark = index >= 4;
            final textColor = isDark ? Colors.white : Colors.black87;

            // 収集済みスタンプ数（ダミー）
            final collectedList = [1, 0, 3, 0, 5];
            final collected = index < collectedList.length
                ? collectedList[index]
                : 0;

            return _StampCard(
              title: card['title']!,
              date: card['date']!,
              bgColor: bgColor,
              textColor: textColor,
              isExpanded: isExpanded,
              collectedStamps: collected,
              totalStamps: 9,
              onTap: () {
                setState(() {
                  // 同じカードをタップしたら閉じる、別のカードなら開く
                  _expandedIndex = isExpanded ? null : index;
                });
              },
            );
          },
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

/// 個別スタンプカードWidget（アコーディオン）
class _StampCard extends StatelessWidget {
  final String title;
  final String date;
  final Color bgColor;
  final Color textColor;
  final bool isExpanded;
  final int collectedStamps;
  final int totalStamps;
  final VoidCallback onTap;

  const _StampCard({
    required this.title,
    required this.date,
    required this.bgColor,
    required this.textColor,
    required this.isExpanded,
    required this.collectedStamps,
    required this.totalStamps,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.45),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ヘッダー（タイトル / 日付 / 矢印アイコン）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 280),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: textColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // スタンプグリッド（開いている時のみ表示）
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 280),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: _buildGrid(),
            ),
          ],
        ),
      ),
    );
  }

  // スタンプグリッド（3列 × n行）
  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: totalStamps,
        itemBuilder: (context, index) {
          final hasStamp = index < collectedStamps;
          return _buildCell(hasStamp);
        },
      ),
    );
  }

  // 1マスのスタンプセル（スタンプ済み or 空）
  Widget _buildCell(bool hasStamp) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: hasStamp
          ? Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'assets/images/stamp_sample.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(Icons.pets, color: AppColors.primary, size: 28),
                ),
              ),
            )
          : const SizedBox(),
    );
  }
}
