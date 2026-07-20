import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/main_buttom_nav.dart';
import '../../home/screens/home_screen.dart';
import '../data/coupon_repository.dart';
import '../models/coupon.dart';
import 'coupon_ticket.dart';

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
    final sections = <({String title, Widget content})>[
      (
        title: 'クーポン内容',
        content: Text(
          coupon.description ?? '${coupon.discountPercent}%OFFでご利用いただけます。',
        ),
      ),
      (
        title: 'ご利用条件',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('有効期限　${formatCouponDate(coupon.endsAt)}'),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '対象　${coupon.unlockSpotName ?? coupon.unlockAnimeTitle ?? '対象店舗'}',
            ),
            if (!coupon.unlocked) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '獲得進捗　${coupon.visitedCount}/${coupon.totalSpotCount}（あと${coupon.remainingCount}か所）',
              ),
            ],
          ],
        ),
      ),
      (
        title: 'ご利用方法',
        content: const Text('店舗レジでこの画面を提示し、スタッフ確認後に「利用する」を押してください。'),
      ),
      (
        title: 'ご利用上の注意',
        content: const Text('クーポンは1枚につき1回限りです。利用確定後の取り消し、換金、払い戻しはできません。'),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      appBar: const AniTrailAppBar(),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                const Expanded(
                  child: Text(
                    'クーポン情報',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.title,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: CouponHeroTicket(coupon: coupon),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: coupon.isUsed
                            ? const Color(0xFF0BC847)
                            : const Color(0xFF173F86),
                        shape: const RoundedRectangleBorder(),
                      ),
                      onPressed: !coupon.unlocked || coupon.isUsed || using
                          ? null
                          : () => _useCoupon(coupon),
                      icon: using
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              coupon.isUsed
                                  ? Icons.check_circle
                                  : Icons.currency_yen,
                            ),
                      label: Text(
                        coupon.isUsed
                            ? '利用済み'
                            : coupon.unlocked
                            ? '利用する'
                            : 'あと${coupon.remainingCount}か所',
                      ),
                    ),
                  ),
                  ...List.generate(sections.length, (index) {
                    final section = sections[index];
                    final expanded = _expandedIndex == index;
                    return Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          const Divider(height: 1),
                          ListTile(
                            title: Text(section.title),
                            trailing: AnimatedRotation(
                              turns: expanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(Icons.keyboard_arrow_down),
                            ),
                            onTap: () => setState(
                              () => _expandedIndex = expanded ? null : index,
                            ),
                          ),
                          if (expanded)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: section.content,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.xxl),
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
