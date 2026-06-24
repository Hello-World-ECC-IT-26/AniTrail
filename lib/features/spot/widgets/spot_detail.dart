import 'package:flutter/material.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/widgets/main_buttom_nav.dart';
import '../../home/screens/home_screen.dart';
import '../../shiori/screens/shiori_list.dart';

class SpotDetailScreen extends StatefulWidget {
  final String placeName;
  final String animeTitle;
  final String sceneDescription;
  final String shrine;
  final String address;
  final String? imagePath;
  final int shioriCount;
  final VoidCallback? onAddToShiori;
  final VoidCallback? onConfirmShiori;

  const SpotDetailScreen({
    super.key,
    this.placeName = '須賀神社',
    this.animeTitle = '「アニメタイトル」',
    this.sceneDescription = 'シーズン○第○話に登場したシーン',
    this.shrine = '東京四谷総鎮守須賀神社',
    this.address = '〒160-0018東京都新宿区須賀町5-6',
    this.imagePath,
    this.shioriCount = 0,
    this.onAddToShiori,
    this.onConfirmShiori,
  });

  @override
  State<SpotDetailScreen> createState() => _SpotDetailScreenState();
}

class _SpotDetailScreenState extends State<SpotDetailScreen> {
  // ブックマーク状態
  bool _isBookmarked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ── AppBar ────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'AniTrail',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Stack(
        children: [
          // ── メインコンテンツ ──────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── タイトルバー（戻るボタン + 場所名） ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.placeName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      // 右側の余白合わせ
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // ── 聖地画像（ブックマーク付き） ────────
                _buildImage(),

                const SizedBox(height: 24),

                // ── アニメタイトル ──────────────────
                Text(
                  widget.animeTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                // ── シーン説明 ──────────────────────
                Text(
                  widget.sceneDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                ),

                const SizedBox(height: 24),

                // ── 住所情報 ────────────────────────
                _buildAddressSection(),

                const SizedBox(height: 20),

                // ── マップで確認ボタン ────────────────
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Googleマップを開く
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
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

                const SizedBox(height: 24),
              ],
            ),
          ),

          // ── しおりに追加バー（下部固定） ────────────
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // しおりに追加ボタン
                Container(
                  color: const Color(0xFF10357A),
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: widget.onAddToShiori ?? () {},
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    label: const Text(
                      'しおりに追加',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                // 旅のしおりを確認ボタン（バッジ付き）
                Positioned(
                  left: 16,
                  bottom: 10,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShioriListScreen(),
                            ),
                          );
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10357A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.location_on_outlined, size: 18),
                        label: const Text(
                          '旅のしおりを作成',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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

  // ── 聖地画像（右上にブックマークアイコン） ───────────
  Widget _buildImage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          // 聖地画像
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: double.infinity,
              height: 220,
              child: Image.asset(
                widget.imagePath ?? 'assets/images/place_sample.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.image_outlined,
                    color: Colors.grey.shade400,
                    size: 50,
                  ),
                ),
              ),
            ),
          ),

          // ブックマークアイコン（右上）
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () => setState(() => _isBookmarked = !_isBookmarked),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 住所セクション ──────────────────────────────────
  Widget _buildAddressSection() {
    return Column(
      children: [
        // 神社名
        Text(
          widget.shrine,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),

        // 住所
        Text(
          widget.address,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}
