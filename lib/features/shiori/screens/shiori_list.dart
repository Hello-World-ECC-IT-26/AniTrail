import 'package:AniTrail/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/widgets/main_buttom_nav.dart';
import '../../../core/widgets/app_bar.dart';
import '../widgets/loading.dart';

class ShioriListScreen extends StatefulWidget {
  /// 追加済み聖地リスト（spot_listから受け取る）
  final List<Map<String, String>> spots;

  const ShioriListScreen({super.key, this.spots = const []});

  @override
  State<ShioriListScreen> createState() => _ShioriListScreenState();
}

class _ShioriListScreenState extends State<ShioriListScreen> {
  // 編集可能な聖地リスト
  late List<Map<String, String>> _spots;

  // ブックマーク済みインデックス
  final Set<int> _bookmarked = {};

  @override
  void initState() {
    super.initState();
    // ダミーデータ（実装時はspot_listから受け取る）
    _spots = widget.spots.isNotEmpty
        ? List.from(widget.spots)
        : [
            {'anime': '君の名は。', 'place': '須賀神社', 'address': '東京都新宿区須賀町5-6'},
            {'anime': '君の名は。', 'place': '須賀神社', 'address': '東京都新宿区須賀町5-6'},
            {'anime': '君の名は。', 'place': '須賀神社', 'address': '東京都新宿区須賀町5-6'},
          ];
  }

  // 聖地を削除する
  void _deleteSpot(int index) {
    setState(() => _spots.removeAt(index));
  }

  // ブックマーク切り替え
  void _toggleBookmark(int index) {
    setState(() {
      _bookmarked.contains(index)
          ? _bookmarked.remove(index)
          : _bookmarked.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // AppBar
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
                  // BACK BUTTON (kiri)
                  Positioned(
                    left: 8,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // TITLE (CENTER PERFECT)
                  const Center(
                    child: Text(
                      '旅のしおり',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── LIST CONTENT ──
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                ...List.generate(_spots.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildSpotCard(index),
                  );
                }),

                const SizedBox(height: 8),

                // ── 行き先を追加ボタン ────────────────
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 130,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.grey.shade500, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '行き先を追加',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
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
            child: Container(
              color: const Color(0xFF10357A),
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatingShioriScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                ),
                child: const Text(
                  'この内容で旅のしおりを作成する',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Nav
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

  // ── 聖地カード ────────────────────────────────────
  Widget _buildSpotCard(int index) {
    final spot = _spots[index];
    final isBookmarked = _bookmarked.contains(index);

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
          // サムネイル + ブックマーク
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 150,
                  height: 130,
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
              ),

              // ブックマークアイコン（左上）
              Positioned(
                top: 6,
                left: 6,
                child: GestureDetector(
                  onTap: () => _toggleBookmark(index),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── テキスト情報 ──────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 削除ボタン（右上・赤）
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton.icon(
                      onPressed: () => _deleteSpot(index),
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
                  ),

                  // アニメタイトル
                  Transform.translate(
                    offset: const Offset(0, -16),
                    child: Text(
                      spot['anime']!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),

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
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
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
    );
  }
}
