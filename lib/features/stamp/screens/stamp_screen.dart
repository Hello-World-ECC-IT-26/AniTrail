import 'package:flutter/material.dart';
import '../../../core/styles/app_styles.dart';
import '../../stamp/widgets/stamp_detail.dart';

class StampScreen extends StatelessWidget {
  const StampScreen({super.key});

  // ダミーのスタンプカードリスト
  static const List<Map<String, dynamic>> _stampCards = [
    {
      'title': 'しおりタイトル',
      'collected': 1,
      'total': 3,
      'remaining': 2,
      'hasStamp': true,
    },
    {
      'title': 'しおりタイトル',
      'collected': 1,
      'total': 3,
      'remaining': 2,
      'hasStamp': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── タイトル ──────────────────────────────
            const Text(
              'スタンプカード',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 16),

            // ── スタンプ数・しおり数カード ──────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              child: Row(
                children: [
                  // キャラクターアイコン
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Image.asset(
                      'assets/images/itachi.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.pets, size: 48, color: AppColors.primary),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // 集めたスタンプ数
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '集めたスタンプ数',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '10',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '個',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // しおり数
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'しおり数',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '3',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── 作成したスタンプカード タイトル ──────────
            const Text(
              '作成したスタンプカード',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 16),

            // ── スタンプカードリスト ──────────────────
            ...List.generate(_stampCards.length, (index) {
              final card = _stampCards[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildStampCard(context, card),
              );
            }),

            // ── しおりを新規作成ボタン ────────────────
            GestureDetector(
              onTap: () {
                // TODO: しおり新規作成画面へ遷移
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 48),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 6),

                    Text(
                      'しおりを新規作成',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── スタンプカード1枚 ─────────────────────────────
  Widget _buildStampCard(BuildContext context, Map<String, dynamic> card) {
    final int collected = card['collected'] as int;
    final int total = card['total'] as int;
    final int filledCount = collected;
    final int remaining = card['remaining'] as int;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StampDetailScreen(title: card['title'] as String),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー（タイトル + n/m + 矢印）
            Row(
              children: [
                Text(
                  card['title'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  '$collected/$total',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // スタンプグリッド（3マス）
            Row(
              children: List.generate(total, (index) {
                final hasThisStamp = index < filledCount;

                return Padding(
                  padding: EdgeInsets.only(right: index < total - 1 ? 10 : 0),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: hasThisStamp
                          ? Colors.transparent
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: hasThisStamp
                        ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey, width: 1),
                            ),
                            child: Image.asset(
                              'assets/images/stamp_sample.png',

                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.pets,
                                color: AppColors.primary,
                                size: 40,
                              ),
                            ),
                          )
                        : const SizedBox(),
                  ),
                );
              }),
            ),

            const SizedBox(height: 10),

            // あと〇箇所でコンプリート！
            Text(
              'あと$remaining箇所でコンプリート!',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
