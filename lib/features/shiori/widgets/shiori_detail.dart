import 'package:flutter/material.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/widgets/main_buttom_nav.dart';

class ShioriDetailScreen extends StatefulWidget {
  final String title;
  final String date;
  final int spotCount;
  final String? bannerImage;

  const ShioriDetailScreen({
    super.key,
    this.title = 'しおりタイトル',
    this.date = '4月1日',
    this.spotCount = 10,
    this.bannerImage,
  });

  @override
  State<ShioriDetailScreen> createState() => _ShioriDetailScreenState();
}

class _ShioriDetailScreenState extends State<ShioriDetailScreen> {
  // ブックマーク済みインデックス
  final Set<int> _bookmarked = {};

  // ダミー行き先リスト（visited: 訪問済みフラグ）
  final List<Map<String, dynamic>> _spots = [
    {
      'anime': '四月は君の嘘',
      'place': '須賀神社',
      'address': '東京都新宿区須賀町5-6',
      'visited': true,
    },
    {
      'anime': '君の膵臓',
      'place': '須賀神社',
      'address': '東京都新宿区須賀町5-6',
      'visited': false,
    },
    {
      'anime': '君の名は。',
      'place': '須賀神社',
      'address': '東京都新宿区須賀町5-6',
      'visited': false,
    },
    {
      'anime': '君の名は。',
      'place': '須賀神社',
      'address': '東京都新宿区須賀町5-6',
      'visited': false,
    },
  ];

  // 訪問済みスタンプ数
  int get _visitedCount => _spots.where((s) => s['visited'] == true).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: CustomScrollView(
        slivers: [
          // ── バナーヘッダー ────────────────────────
          _buildSliverAppBar(),

          // ── コンテンツ ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── スタンプカード ──────────────────
                  _buildStampCard(),

                  const SizedBox(height: 16),

                  // ── 行き先一覧ヘッダー ──────────────
                  Row(
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
                            '行き先一覧',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 70),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── 行き先カードリスト ──────────────
                  ...List.generate(_spots.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildSpotCard(index),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── ボトムナビゲーション ──────────────────────
      bottomNavigationBar: MainBottomNav(
        onTap: (index) => Navigator.pop(context, index),
      ),
    );
  }

  // ── バナーヘッダー ────────────────────────────────
  SliverAppBar _buildSliverAppBar() {
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
            widget.bannerImage != null
                ? Image.asset(widget.bannerImage!, fit: BoxFit.cover)
                : Image.asset(
                    'assets/images/place_sample.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppColors.primary),
                  ),

            // グラデーションオーバーレイ
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black26, Colors.black54],
                ),
              ),
            ),

            // タイトル・日付・聖地数
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.date,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white70,
                        size: 13,
                      ),
                      const SizedBox(width: 2),
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

  // ── スタンプカード ────────────────────────────────
  Widget _buildStampCard() {
    return Container(
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
          // ヘッダー（スタンプカード + 1/10）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'スタンプカード',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '$_visitedCount/${widget.spotCount}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // スタンプグリッド（5列 × 2行）
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: widget.spotCount,
            itemBuilder: (_, index) {
              final hasStamp = index < _visitedCount;

              return Container(
                decoration: BoxDecoration(
                  color: hasStamp ? Colors.white : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: hasStamp
                      ? Border.all(color: Colors.grey.shade200, width: 2)
                      : null,
                ),
                child: hasStamp
                    ? Padding(
                        padding: EdgeInsets.zero,
                        child: Image.asset(
                          'assets/images/stamp_sample.png',
                          fit: BoxFit.cover,
                        ),
                      )
                    : const SizedBox(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── 行き先カード1枚 ───────────────────────────────
  Widget _buildSpotCard(int index) {
    final spot = _spots[index];
    final isBookmarked = _bookmarked.contains(index);
    final isVisited = spot['visited'] as bool;

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
                  width: 110,
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
              ),

              // ブックマークアイコン（左上）
              Positioned(
                top: 6,
                left: 6,
                child: GestureDetector(
                  onTap: () => setState(() {
                    isBookmarked
                        ? _bookmarked.remove(index)
                        : _bookmarked.add(index);
                  }),
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
                  // 訪問済み / 未訪問バッジ（右上）
                  Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      isVisited ? '訪問済み' : '未訪問',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isVisited ? Colors.black54 : Colors.red.shade400,
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
