import 'package:AniTrail/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/widgets/main_buttom_nav.dart';
import '../../shiori/screens/shiori_list.dart';

class SpotList extends StatefulWidget {
  final String animeTitle;
  final String? bannerImage;
  final int spotCount;

  const SpotList({
    super.key,
    required this.animeTitle,
    this.bannerImage,
    this.spotCount = 10,
  });

  @override
  State<SpotList> createState() => _SpotListState();
}

class _SpotListState extends State<SpotList> {
  // しおりに追加した聖地数（バッジ表示用）
  int _shioriCount = 0;

  // ブックマーク済みの聖地インデックス
  final Set<int> _bookmarked = {};

  // ダミーの聖地リスト
  final List<Map<String, String>> _spots = [
    {'anime': '四月は君の嘘', 'place': '須賀神社', 'address': '東京都新宿区須賀町5-6'},
    {'anime': '君の膵臓をたべたい', 'place': '須賀神社', 'address': '東京都新宿区須賀町5-6'},
    {'anime': '君の名は。', 'place': '須賀神社', 'address': '東京都新宿区須賀町5-6'},
    {'anime': '君の名は。', 'place': '須賀神社', 'address': '東京都新宿区須賀町5-6'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── メインコンテンツ ──────────────────────
          CustomScrollView(
            slivers: [
              // アニメバナーヘッダー
              _buildSliverAppBar(),

              // 聖地カードリスト
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildSpotCard(index),
                    ),
                    childCount: _spots.length,
                  ),
                ),
              ),
            ],
          ),

          // ── 旅のしおりを作成ボタン（左下固定） ─────
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
                        builder: (_) => ShioriListScreen(spots: _spots),
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),

                // バッジ（追加数）
                if (_shioriCount > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$_shioriCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  // ── アニメバナーヘッダー ────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // バナー画像
            Stack(
              fit: StackFit.expand,
              children: [
                widget.bannerImage != null
                    ? Image.asset(widget.bannerImage!, fit: BoxFit.cover)
                    : Image.asset(
                        'assets/images/place_sample.jpg',
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.9),
                      ),

                // Overlay
                Container(color: Colors.white.withValues(alpha: 0.2)),
              ],
            ),

            // タイトルと聖地数
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.animeTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black)],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '聖地 ${widget.spotCount}箇所',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 聖地カード1枚 ───────────────────────────────────
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
          // ── サムネイル + ブックマーク ──────────────
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
                  onTap: () {
                    setState(() {
                      isBookmarked
                          ? _bookmarked.remove(index)
                          : _bookmarked.add(index);
                    });
                  },
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
                  // ＋追加ボタン（右上）
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _shioriCount++),
                      icon: const Icon(
                        Icons.add,
                        size: 14,
                        color: Colors.black,
                      ),
                      label: const Text(
                        '追加',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
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
