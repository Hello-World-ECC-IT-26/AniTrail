import 'package:flutter/material.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/widgets/main_buttom_nav.dart';
import '../../../core/widgets/app_bar.dart';
import '../../home/screens/home_screen.dart';
import '../../shiori/widgets/shiori_edit.dart';

class ShioriCompleteScreen extends StatelessWidget {
  /// 作成したしおりのタイトル
  final String shioriTitle;

  /// しおりに追加した聖地リスト
  final List<Map<String, String>> spots;

  const ShioriCompleteScreen({
    super.key,
    this.shioriTitle = 'しおりタイトル',
    this.spots = const [],
  });

  @override
  Widget build(BuildContext context) {
    // ダミースポット（実装時はspotsを使用）
    final displaySpots = spots.isNotEmpty
        ? spots
        : [
            {'anime': '君の名は。', 'place': '須賀神社', 'address': '東京都新宿区須賀町5-6'},
            {'anime': '君の名は。', 'place': '須賀神社', 'address': '東京都新宿区須賀町5-6'},
            {'anime': '君の名は。', 'place': '', 'address': ''},
          ];

    return Scaffold(
      backgroundColor: Colors.white,

      // AppBar
      appBar: const AniTrailAppBar(),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 完了タイトル ──────────────────────────
            const Center(
              child: Text(
                '旅のしおりが作成されました！',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── しおりカード ──────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── ヘッダー（タイトル + 編集・削除） ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        shioriTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          // 編集ボタン
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ShioriEditScreen(spots: displaySpots),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                            label: const Text(
                              '編集',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),

                          const SizedBox(width: 12),

                          // 削除ボタン
                          TextButton.icon(
                            onPressed: () {
                              // TODO: しおり削除処理
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 14,
                              color: Colors.red,
                            ),
                            label: const Text(
                              '削除',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red,
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
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── 聖地リスト ──────────────────────
                  ...displaySpots.map((spot) => _buildSpotRow(spot)),

                  const SizedBox(height: 20),

                  // ── スタンプカード ──────────────────
                  const Text(
                    'スタンプカード',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // スタンプグリッド（5列 × 2行 = 10マス）
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
                    itemCount: 10,
                    itemBuilder: (_, __) => Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── スタンプ促進テキスト ──────────────────
            const Center(
              child: Text(
                '聖地を巡ってスタンプをゲットしましょう！',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── マップで確認ボタン ────────────────────
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: マップ画面へ遷移
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  'マップで確認',
                  style: TextStyle(fontSize: 15, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),

      // ── ボトムナビゲーション ──────────────────────
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

  // ── 聖地の1行表示 ────────────────────────────────
  Widget _buildSpotRow(Map<String, String> spot) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // サムネイル
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              child: SizedBox(
                width: 120,
                height: 100,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
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
                    // ブックマークアイコン
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bookmark_outline,
                          color: AppColors.primary,
                          size: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── テキスト情報 ──────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // アニメタイトル
                    Transform.translate(
                      offset: const Offset(0, 2),
                      child: Text(
                        spot['anime']!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // 場所名
                    Text(
                      spot['place']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // 住所
                    Text(
                      spot['address']!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                      ),
                    ),

                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                        // 詳細ボタン → spot_detail_screenへ遷移
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('詳細', style: TextStyle(fontSize: 14)),
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
}
