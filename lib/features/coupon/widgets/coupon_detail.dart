import 'package:flutter/material.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/widgets/main_buttom_nav.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/widgets/app_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/app_bottom_action_bar.dart';
import 'coupon_content.dart';
import 'coupon_condition.dart';
import 'coupon_howtouse.dart';
import 'coupon_notice.dart';

class CouponDetailScreen extends StatefulWidget {
  final Map<String, String> coupon;
  const CouponDetailScreen({super.key, required this.coupon});
  @override
  State<CouponDetailScreen> createState() => _CouponDetailScreenState();
}

class AccordionItem {
  final String title;
  final Widget content;

  const AccordionItem({required this.title, required this.content});
}

class _CouponDetailScreenState extends State<CouponDetailScreen> {
  int? _expandedIndex;
  final List<AccordionItem> _accordionItems = [
    AccordionItem(title: 'クーポン内容', content: const CouponContent()),
    AccordionItem(title: 'ご利用条件', content: const CouponCondition()),
    AccordionItem(title: 'ご利用方法', content: const CouponHowToUse()),
    AccordionItem(title: 'ご利用上の注意', content: const CouponNotice()),
  ];

  //  PERBAIKAN: Menggunakan => and widget.coupon
  bool get isAnimeGoods => widget.coupon['icon'] == 'anime_goods';
  bool isFavorite = false;

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
            padding: const EdgeInsets.fromLTRB(4, 20, 16, 20),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFFFF),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
              ),
            ),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    margin: const EdgeInsets.only(top: 25),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
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
                            padding: const EdgeInsets.fromLTRB(30, 25, 30, 5),
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
                                      style: GoogleFonts.lunasima(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.0,
                                      ),
                                    ),
                                    Text(
                                      widget.coupon['title'] ?? '',
                                      style: GoogleFonts.lunasima(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: widget.coupon['discount']!,
                                        style: GoogleFonts.lusitana(
                                          fontSize: 100,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      WidgetSpan(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '%',
                                              style: GoogleFonts.lusitana(
                                                fontSize: 48,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                height: 1.0,
                                              ),
                                            ),
                                            Text(
                                              'OFF',
                                              style: GoogleFonts.lusitana(
                                                fontSize: 26,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                height: 1.0,
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
                          ),
                          // スカラップ区切り
                          CustomPaint(
                            size: const Size(double.infinity, 10),
                            painter: _ScallopPainter(),
                          ),

                          // 下部: 説明
                          Container(
                            height: 240,
                            decoration: const BoxDecoration(
                              color: Colors.white,
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
                                    35,
                                    35,
                                    35,
                                    35,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          spacing: 48,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.coupon['description'] ??
                                                  'アニメ「〇〇」の聖地\n「〇〇店」の食事で\n10%OFFでご利用できます',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '有効期限',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                Text(
                                                  '${widget.coupon['expiry'] ?? ''}(土)',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      SvgPicture.asset(
                                        isAnimeGoods
                                            ? 'assets/images/goods.svg'
                                            : 'assets/images/food.svg',
                                        width: 150,
                                        height: 170,
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
                    margin: const EdgeInsets.only(top: 25),
                    child: AppBottomActionBar(
                      icon: isFavorite
                          ? Icons.check_circle
                          : Icons.currency_yen,
                      label: isFavorite ? '利用済み' : '利用する',
                      backgroundColor: isFavorite
                          ? const Color(0xFF0BC847)
                          : const Color(0xFF10357A),
                      onPressed: () {
                        setState(() {
                          isFavorite = !isFavorite;
                        });
                      },
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
                          const Divider(height: 1, indent: 0),
                      itemBuilder: (context, index) {
                        final item = _accordionItems[index];
                        final isExpanded = _expandedIndex == index;
                        return Column(
                          children: [
                            ListTile(
                              title: Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              trailing: AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.grey.shade400,
                                ),
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
                                child: item.content,
                              ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),
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

class _ScallopPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bluePaint = Paint()..color = AppColors.primary;
    final whitePaint = Paint()..color = Colors.white;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bluePaint);

    const radius = 11.0;
    const gap = 10.0;
    const margin = 8.0;

    for (
      double x = margin + radius;
      x <= size.width - margin - radius;
      x += radius * 3 + gap
    ) {
      canvas.drawCircle(Offset(x, size.height), radius, whitePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const margin = 9.0;
    final rect = Rect.fromLTWH(
      margin,
      margin,
      size.width - margin * 2,
      size.height - margin * 2,
    );

    void drawDashedLine(Offset start, Offset end) {
      const dash = 5.0;
      const gap = 5.0;
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final distance = (end - start).distance;
      final direction = Offset(dx / distance, dy / distance);
      double current = 0;
      while (current < distance) {
        final from = start + direction * current;
        final to = start + direction * (current + dash).clamp(0, distance);
        canvas.drawLine(from, to, paint);
        current += dash + gap;
      }
    }

    //内側のborder
    drawDashedLine(Offset(rect.left, rect.top), Offset(rect.right, rect.top));

    drawDashedLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.bottom),
    );

    drawDashedLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.left, rect.bottom),
    );

    drawDashedLine(Offset(rect.left, rect.bottom), Offset(rect.left, rect.top));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
