import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/styles/app_styles.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/app_bottom_action_bar.dart';
import '../../../core/widgets/main_buttom_nav.dart';
import '../../home/screens/home_screen.dart';
import '../data/coupon_repository.dart';
import '../models/coupon.dart';

class CouponDetailScreen extends StatefulWidget {
  const CouponDetailScreen({super.key, required this.coupon});

  final Coupon coupon;

  @override
  State<CouponDetailScreen> createState() => _CouponDetailScreenState();
}

class _CouponDetailScreenState extends State<CouponDetailScreen> {
  int? _expandedIndex;

  Coupon _currentCoupon(CouponRepository repository) {
    for (final coupon in repository.coupons) {
      if (coupon.id == widget.coupon.id) return coupon;
    }
    return widget.coupon;
  }

  Future<void> _useCoupon(Coupon coupon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('クーポンを利用しますか？'),
        content: const Text('利用確定後は取り消せません。店舗スタッフへ画面を提示してから確定してください。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('利用を確定'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<CouponRepository>().useCoupon(coupon.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('クーポンを利用できませんでした: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<CouponRepository>();
    final coupon = _currentCoupon(repository);
    final using = repository.isUsing(coupon.id);
    final canUse = coupon.unlocked && coupon.availableCount > 0 && !using;
    final sections = <({String title, Widget content})>[
      (title: 'クーポン内容', content: _CouponContent(coupon: coupon)),
      (title: 'ご利用条件', content: _CouponCondition(coupon: coupon)),
      (title: 'ご利用方法', content: const _CouponHowToUse()),
      (title: 'ご利用上の注意', content: const _CouponNotice()),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AniTrailAppBar(),
      body: Column(
        children: [
          _DetailHeader(onBack: () => Navigator.pop(context)),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 25, 16, 0),
                    child: _CouponVisual(coupon: coupon),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 25),
                    child: AppBottomActionBar(
                      icon: using
                          ? null
                          : coupon.isUsed
                          ? Icons.check_circle
                          : Icons.currency_yen,
                      label: using
                          ? '処理中…'
                          : coupon.isUsed
                          ? '利用済み'
                          : !coupon.unlocked
                          ? 'あと${coupon.remainingCount}か所'
                          : coupon.repeatable
                          ? '利用する（残り${coupon.availableCount}枚）'
                          : '利用する',
                      backgroundColor: coupon.isUsed
                          ? const Color(0xFF0BC847)
                          : const Color(0xFF10357A),
                      onPressed: canUse ? () => _useCoupon(coupon) : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    color: Colors.white,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sections.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final section = sections[index];
                        final expanded = _expandedIndex == index;
                        return Column(
                          children: [
                            ListTile(
                              title: Text(
                                section.title,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: AnimatedRotation(
                                turns: expanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              onTap: () => setState(
                                () => _expandedIndex = expanded ? null : index,
                              ),
                            ),
                            if (expanded)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                child: section.content,
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
      bottomNavigationBar: MainBottomNav(
        currentIndex: 3,
        onTap: (index) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: index)),
            (_) => false,
          );
        },
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(4, 20, 16, 20),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
    ),
    child: Row(
      children: [
        Transform.translate(
          offset: const Offset(8, 0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        const Expanded(
          child: Text(
            'クーポン情報',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    ),
  );
}

class _CouponVisual extends StatelessWidget {
  const _CouponVisual({required this.coupon});

  final Coupon coupon;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(30, 25, 30, 5),
          color: AppColors.primary,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        coupon.categoryLabel,
                        style: GoogleFonts.lunasima(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'COUPON',
                        maxLines: 1,
                        softWrap: false,
                        style: GoogleFonts.lunasima(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${coupon.discountPercent}',
                        style: GoogleFonts.lusitana(
                          color: Colors.white,
                          fontSize: 100,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '%',
                            style: GoogleFonts.lusitana(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                          Text(
                            'OFF',
                            style: GoogleFonts.lusitana(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const CustomPaint(
          size: Size(double.infinity, 10),
          painter: _ScallopPainter(),
        ),
        SizedBox(
          height: 240,
          child: Stack(
            children: [
              const Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CustomPaint(painter: _DashedBorderPainter()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(35),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coupon.description ??
                                '${coupon.title}を${coupon.discountPercent}%OFFでご利用いただけます。',
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '有効期限',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _formatCouponDate(coupon.endsAt),
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SvgPicture.asset(
                      coupon.isAnimeGoods
                          ? 'assets/images/goods.svg'
                          : 'assets/images/food.svg',
                      width: 130,
                      height: 170,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
              if (!coupon.unlocked)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.76),
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'あと${coupon.remainingCount}か所で獲得',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (coupon.isUsed)
                const Positioned.fill(
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Text(
                          '利用済み',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
  );
}

class _CouponContent extends StatelessWidget {
  const _CouponContent({required this.coupon});

  final Coupon coupon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          coupon.description ??
              '${coupon.title}を${coupon.discountPercent}%OFFでご利用いただけます。',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        Text(
          '・1商品につき、クーポン券1枚をご利用いただけます。\n'
          '・他の割引サービスとの併用はできません。\n'
          '・割引後の金額はレジにてご確認ください。',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    ),
  );
}

class _CouponCondition extends StatelessWidget {
  const _CouponCondition({required this.coupon});

  final Coupon coupon;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _InfoRow(
        title: '対象商品',
        value: '${coupon.title}（${coupon.discountPercent}%OFF）',
      ),
      _InfoRow(title: '有効期限', value: _formatCouponDate(coupon.endsAt)),
      _InfoRow(
        title: '対象店舗',
        value: coupon.unlockSpotName ?? coupon.unlockAnimeTitle ?? '対象店舗',
      ),
      if (!coupon.unlocked)
        _InfoRow(
          title: '獲得進捗',
          value:
              '${coupon.visitedCount}/${coupon.totalSpotCount}（あと${coupon.remainingCount}か所）',
        ),
      if (coupon.repeatable && coupon.unlocked)
        _InfoRow(
          title: '所持枚数',
          value: '${coupon.availableCount}枚（累計${coupon.acquiredCount}枚獲得）',
        ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(title, style: const TextStyle(color: Colors.grey)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.blue)),
        ),
      ],
    ),
  );
}

class _CouponHowToUse extends StatelessWidget {
  const _CouponHowToUse();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      _StepRow(number: '1', value: '対象店舗へ'),
      _StepRow(number: '2', value: '店舗レジでクーポンを提示し「利用する」を押す'),
      _StepRow(number: '3', value: 'お好きな商品を注文する'),
    ],
  );
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.value});

  final String number;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 30,
          child: Text(number, style: const TextStyle(color: Colors.grey)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.blue)),
        ),
      ],
    ),
  );
}

class _CouponNotice extends StatelessWidget {
  const _CouponNotice();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Text(
      '・換金や払い戻しはできません\n'
      '・他の割引サービスとの併用はできません\n'
      '・クーポンの利用は1枚につき1回限りです\n'
      '・商品品切れの際にはご了承ください',
      style: TextStyle(color: Colors.grey[600]),
    ),
  );
}

class _ScallopPainter extends CustomPainter {
  const _ScallopPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bluePaint = Paint()..color = AppColors.primary;
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bluePaint);

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
  bool shouldRepaint(_ScallopPainter oldDelegate) => false;
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

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
      final distance = (end - start).distance;
      final direction = Offset(
        (end.dx - start.dx) / distance,
        (end.dy - start.dy) / distance,
      );
      var current = 0.0;
      while (current < distance) {
        final from = start + direction * current;
        final to = start + direction * (current + dash).clamp(0, distance);
        canvas.drawLine(from, to, paint);
        current += dash + gap;
      }
    }

    drawDashedLine(rect.topLeft, rect.topRight);
    drawDashedLine(rect.topRight, rect.bottomRight);
    drawDashedLine(rect.bottomRight, rect.bottomLeft);
    drawDashedLine(rect.bottomLeft, rect.topLeft);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}

String _formatCouponDate(DateTime value) {
  final local = value.toLocal();
  return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
}
