import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/styles/app_styles.dart';
import '../../coupon/widgets/coupon_detail.dart';

class CouponScreen extends StatefulWidget {
  const CouponScreen({super.key});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  // 現在のソート順
  String _sortOrder = '新着順';

  // 絞り込みフィルター（nullなら全て表示）
  String? _filterType;

  final List<Map<String, String>> _allCoupons = [
    {
      'type': 'DRINK FOOD',
      'title': 'COUPON',
      'discount': '10',
      'expiry': '2026/10/31',
      'icon': 'drink_food',
      'description': 'アニメ「〇〇」の聖地「〇〇店」の食事で10%OFFでご利用できます',
    },
    {
      'type': 'DRINK FOOD',
      'title': 'COUPON',
      'discount': '10',
      'expiry': '2026/10/31',
      'icon': 'drink_food',
      'description': 'アニメ「〇〇」の聖地「〇〇店」の食事で10%OFFでご利用できます',
    },
    {
      'type': 'ANIME GOODS',
      'title': 'COUPON',
      'discount': '10',
      'expiry': '2026/10/31',
      'icon': 'anime_goods',
      'description': '対象店舗のアニメグッズを10%OFFでご利用できます',
    },
  ];

  // フィルター後のクーポンリスト
  List<Map<String, String>> get _filteredCoupons {
    if (_filterType == null) return _allCoupons;
    return _allCoupons.where((c) => c['icon'] == _filterType).toList();
  }

  // ソート・絞り込みボトムシートを表示
  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '並び替え',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const Divider(),

              // 新着順
              _buildSortOption(ctx, setSheetState, '新着順'),

              const Divider(indent: 0),

              // 有効期限順
              _buildSortOption(ctx, setSheetState, '有効期限順'),

              const SizedBox(height: 16),

              // 絞り込みタイトル
              const Text(
                '絞り込み',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const Divider(),

              // ドリンク&フード
              _buildFilterOption(ctx, setSheetState, 'ドリンク&フード', 'drink_food'),

              const Divider(indent: 0),

              // アニメグッズ
              _buildFilterOption(ctx, setSheetState, 'アニメグッズ', 'anime_goods'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext ctx,
    StateSetter setSheetState,
    String label,
  ) {
    final isSelected = _sortOrder == label;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary, size: 20)
          : null,
      onTap: () {
        setSheetState(() {});
        setState(() => _sortOrder = label);
        Navigator.pop(ctx);
      },
    );
  }

  Widget _buildFilterOption(
    BuildContext ctx,
    StateSetter setSheetState,
    String label,
    String value,
  ) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 15)),
      onTap: () {
        setSheetState(() {});
        setState(() {
          _filterType = _filterType == value ? null : value;
        });
        Navigator.pop(ctx);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // タイトル
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Center(
              child: Text(
                'クーポン一覧',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          const Divider(thickness: 1, color: Colors.black12),

          // ソートボタン
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _showSortSheet,
                  child: Row(
                    children: [
                      const Icon(Icons.sort, size: 16, color: Colors.black87),
                      const Icon(
                        Icons.arrow_downward,
                        size: 14,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _sortOrder,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // クーポンリスト
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _filteredCoupons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final coupon = _filteredCoupons[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CouponDetailScreen(coupon: coupon),
                      ),
                    );
                  },
                  child: _buildCouponCard(coupon),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard(Map<String, String> coupon) {
    final isAnimeGoods = coupon['icon'] == 'anime_goods';

    return SizedBox(
      height: 130,
      child: CustomPaint(
        painter: CouponBackgroundPainter(
          borderColor: AppColors.primary,
          bgColorRight: AppColors.primary,
          bgColorLeft: Colors.white,
        ),
        child: Row(
          children: [
            // 左側: クーポン情報
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _DashedBorderPainter()),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  coupon['type']!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  coupon['title']!,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            SvgPicture.asset(
                              isAnimeGoods
                                  ? 'assets/images/goods.svg'
                                  : 'assets/images/food.svg',
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              coupon['expiry']!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
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

            // 右側: 割引率
            SizedBox(
              width: 110,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pets, color: Colors.white70, size: 20),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: coupon['discount']!,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const TextSpan(
                            text: '%\nOFF',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.pets, color: Colors.white70, size: 20),
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

class CouponBackgroundPainter extends CustomPainter {
  final Color borderColor;
  final Color bgColorLeft;
  final Color bgColorRight;

  CouponBackgroundPainter({
    required this.borderColor,
    required this.bgColorLeft,
    required this.bgColorRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final dividerX = size.width - 110;
    const notchRadius = 16.0;

    // 1. Gambar Background Kiri (Putih) -> 修正箇所
    final pathLeft = Path();
    pathLeft.moveTo(0, 0);
    pathLeft.lineTo(dividerX, 0);
    pathLeft.lineTo(dividerX, size.height);
    pathLeft.lineTo(0, size.height);
    pathLeft.close();
    paint.color = bgColorLeft;
    canvas.drawPath(pathLeft, paint);

    // 2. Gambar Background Kanan (Biru)
    final pathRight = Path();
    pathRight.moveTo(dividerX, 0);
    pathRight.lineTo(size.width, 0);
    pathRight.lineTo(size.width, (size.height / 2) - notchRadius);
    pathRight.arcToPoint(
      Offset(size.width, (size.height / 2) + notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    pathRight.lineTo(size.width, size.height);
    pathRight.lineTo(dividerX, size.height);
    pathRight.close();
    paint.color = bgColorRight;
    canvas.drawPath(pathRight, paint);

    // 3. Gambar Garis Outline/Border Luar Kupon
    final borderPath = Path();
    borderPath.moveTo(0, 0);
    borderPath.lineTo(size.width, 0);
    borderPath.lineTo(size.width, (size.height / 2) - notchRadius);
    borderPath.arcToPoint(
      Offset(size.width, (size.height / 2) + notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    borderPath.lineTo(size.width, size.height);
    borderPath.lineTo(0, size.height);
    borderPath.close();
    canvas.drawPath(borderPath, strokePaint);

    // 4. Gambar Garis Putus-Putus Vertikal Pembatas
    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashHeight = 5.0;
    const dashSpace = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(dividerX, startY),
        Offset(dividerX, startY + dashHeight),
        dashPaint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    const margin = 6.0;
    final rect = Rect.fromLTWH(
      margin,
      margin,
      size.width - margin * 2,
      size.height - margin * 2,
    );

    void drawLine(Offset start, Offset end) {
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final length = (dx * dx + dy * dy).abs();
      if (length <= 0) return; // 0以下のチェックで安全性を向上
      final count = length / (dashWidth + dashSpace);
      final stepX = dx / count;
      final stepY = dy / count;
      final dX = stepX * (dashWidth / (dashWidth + dashSpace));
      final dY = stepY * (dashWidth / (dashWidth + dashSpace));
      var cur = start;
      for (var i = 0; i < count; i++) {
        canvas.drawLine(cur, Offset(cur.dx + dX, cur.dy + dY), paint);
        cur = Offset(cur.dx + stepX, cur.dy + stepY);
      }
    }

    drawLine(Offset(rect.left, rect.top), Offset(rect.right, rect.top));
    drawLine(Offset(rect.right, rect.top), Offset(rect.right, rect.bottom));
    drawLine(Offset(rect.right, rect.bottom), Offset(rect.left, rect.bottom));
    drawLine(Offset(rect.left, rect.bottom), Offset(rect.left, rect.top));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
