import 'package:flutter/material.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/widgets/main_buttom_nav.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/widgets/app_bar.dart';

class CouponDetailScreen extends StatefulWidget {
  final Map<String, String> coupon;

  const CouponDetailScreen({super.key, required this.coupon});

  @override
  State<CouponDetailScreen> createState() => _CouponDetailScreenState();
}

class _CouponDetailScreenState extends State<CouponDetailScreen> {
  int? _expandedIndex;

  final List<Map<String, String>> _accordionItems = [
    {'title': 'クーポン内容', 'content': 'アニメ「〇〇」の聖地「〇〇店」の食事で10%OFFでご利用できます。'},
    {'title': 'ご利用条件', 'content': '・本クーポンは1回のみ有効です。\n・他のクーポンとの併用はできません。'},
    {'title': 'ご利用方法', 'content': '会計時にスタッフにアプリ画面をご提示ください。'},
    {'title': 'ご利用上の注意', 'content': '・有効期限を過ぎたクーポンはご利用できません。\n・返金・換金はできません。'},
  ];

  //  PERBAIKAN: Menggunakan => dan widget.coupon
  bool get isAnimeGoods => widget.coupon['icon'] == 'anime_goods';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      // アプリバー
      appBar: const AniTrailAppBar(),

      body: Column(
        children: [
          // ── ヘッダーバー（戻る + タイトル） ────────────
          Container(
            margin: const EdgeInsets.symmetric(vertical: 14),
            color: const Color(0xFFFFFFFF),
            padding: const EdgeInsets.fromLTRB(4, 12, 16, 12),

            child: Row(
              children: [
                Transform.translate(
                  offset: const Offset(8, 0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'クーポン情報',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── クーポンビジュアルカード ────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 上部: 青いバナー
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.coupon['type'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    Text(
                                      widget.coupon['title'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: widget.coupon['discount'] ?? '0',
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: '%\nOFF',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ギザギザ区切り
                          CustomPaint(
                            size: const Size(double.infinity, 16),
                            painter: _ZigzagPainter(),
                          ),

                          // 下部: 説明
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: CustomPaint(
                                      painter: _DashedBorderPainter(),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    16,
                                    16,
                                    16,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.coupon['description'] ??
                                                  'アニメ「〇〇」の聖地\n「〇〇店」の食事で\n10%OFFでご利用できます',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade700,
                                                height: 1.6,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              '有効期限',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            Text(
                                              '${widget.coupon['expiry'] ?? ''}(土)',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

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
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 利用するボタン
                  Container(
                    color: const Color(0xFF10357A),
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 16),
                    child: TextButton.icon(
                      onPressed: () {
                        // TODO: クーポン利用処理
                      },
                      icon: const Icon(
                        Icons.currency_yen,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        '利用する',
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

                  const SizedBox(height: 8),

                  // アコーディオン
                  Container(
                    color: Colors.white,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _accordionItems.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16),
                      itemBuilder: (context, index) {
                        final item = _accordionItems[index];
                        final isExpanded = _expandedIndex == index;
                        return Column(
                          children: [
                            ListTile(
                              title: Text(
                                item['title']!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              trailing: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.grey.shade400,
                              ),
                              onTap: () => setState(() {
                                _expandedIndex = isExpanded ? null : index;
                              }),
                            ),
                            if (isExpanded)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                child: Text(
                                  item['content']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MainBottomNav(onTap: (index) {}),
    );
  }
}

class _ZigzagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintWhite = Paint()..color = Colors.white;
    final paintBlue = Paint()..color = AppColors.primary;
    const zigzagWidth = 12.0;
    final count = (size.width / zigzagWidth).ceil();
    final path = Path();
    path.moveTo(0, 0);
    for (var i = 0; i < count; i++) {
      final x = i * zigzagWidth;
      path.lineTo(x + zigzagWidth / 2, size.height);
      path.lineTo(x + zigzagWidth, 0);
    }
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height / 2),
      paintBlue,
    );
    canvas.drawPath(path, paintWhite);
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

    void drawLine(Offset start, Offset end) {
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final length = (dx * dx + dy * dy).abs();
      if (length == 0) return;
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

    drawLine(const Offset(0, 0), Offset(size.width, 0));
    drawLine(Offset(size.width, 0), Offset(size.width, size.height));
    drawLine(Offset(size.width, size.height), Offset(0, size.height));
    drawLine(Offset(0, size.height), const Offset(0, 0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
