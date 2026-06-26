import 'package:flutter/material.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/widgets/main_buttom_nav.dart';
import '../../../core/widgets/app_bar.dart';
import '../../home/screens/home_screen.dart';

class StampDetailScreen extends StatelessWidget {
  final String title;

  const StampDetailScreen({super.key, this.title = 'しおりタイトル'});

  // ダミーの行き先リスト
  static const List<Map<String, dynamic>> _spots = [
    {
      'anime': '君の名は。',
      'place': '須賀神社',
      'address': '東京都新宿区須賀町5-6',
      'visited': true,
    },
    {
      'anime': '君の名は。',
      'place': '須賀神社',
      'address': '東京都新宿区須賀町5-6',
      'visited': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final visitedCount = _spots.where((s) => s['visited'] == true).length;
    final totalCount = _spots.length;

    return Scaffold(
      backgroundColor: Colors.white,

      // アプリバー
      appBar: const AniTrailAppBar(),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── タイトルバー（戻る + しおりタイトル） ────
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── スタンプカード ──────────────────────────
            Container(
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
                  const Text(
                    'スタンプカード',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // スタンプグリッド（5列 × 2行）
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                    itemCount: 10,
                    itemBuilder: (_, index) {
                      final hasStamp = index < visitedCount;

                      return Container(
                        decoration: BoxDecoration(
                          color: hasStamp ? Colors.white : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: hasStamp
                              ? Border.all(color: Colors.grey, width: 1)
                              : null,
                        ),
                        child: hasStamp
                            ? Padding(
                                padding: const EdgeInsets.all(4),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.asset(
                                    'assets/images/stamp_sample.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.pets,
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── 行き先一覧タイトル ──────────────────────
            const Center(
              child: Text(
                '行き先一覧',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── 行き先カードリスト ──────────────────────
            ...List.generate(_spots.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSpotCard(_spots[index]),
              );
            }),

            const SizedBox(height: 16),

            // ── マップで確認ボタン ──────────────────────
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: マップ画面へ遷移
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.location_on_outlined, size: 18),
                label: const Text(
                  'マップで確認',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),

      // ── ボトムナビゲーション ──────────────────────
      bottomNavigationBar: MainBottomNav(
        currentIndex: 2,
        onTap: (index) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: index)),
            (route) => false,
          );
        },
      ),
    );
  }

  // ── 行き先カード1枚 ───────────────────────────────
  Widget _buildSpotCard(Map<String, dynamic> spot) {
    final bool isVisited = spot['visited'] as bool;

    return Container(
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
      child: Row(
        children: [
          // サムネイル画像
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: Stack(
              children: [
                SizedBox(
                  width: 120,
                  height: 110,
                  child: Image.asset(
                    'assets/images/place_sample.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.image_outlined,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),

                // 訪問済みオーバーレイ（チェックマーク）
                if (isVisited)
                  Container(
                    width: 120,
                    height: 110,
                    color: Colors.white.withOpacity(0.5),
                    child: const Center(
                      child: Icon(Icons.check, color: Colors.black54, size: 36),
                    ),
                  ),
              ],
            ),
          ),

          // テキスト情報
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // アニメタイトル
                  Text(
                    spot['anime'] as String,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 3),

                  // 場所名
                  Text(
                    spot['place'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // 住所
                  Text(
                    spot['address'] as String,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),

                  const SizedBox(height: 8),

                  // 訪問済み or 詳細ボタン
                  Align(
                    alignment: Alignment.bottomRight,
                    child: isVisited
                        ? ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0BC847),
                              disabledBackgroundColor: const Color(0xFF0BC847),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              '訪問済み',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              // TODO: 詳細画面へ遷移
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              '詳細',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
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
