import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_styles.dart';
import '../models/coupon.dart';

String formatCouponDate(DateTime value) {
  final local = value.toLocal();
  return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
}

class CouponTicketCard extends StatelessWidget {
  const CouponTicketCard({super.key, required this.coupon});

  final Coupon coupon;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Opacity(
      opacity: coupon.isUsed ? 0.5 : 1,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 64,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: DottedBorder(
                      options: const RectDottedBorderOptions(
                        color: AppColors.primary,
                        strokeWidth: 1.2,
                        dashPattern: [6, 4],
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 8 : 16,
                          compact ? 12 : 20,
                          compact ? 4 : 8,
                          compact ? 8 : 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      coupon.categoryLabel,
                                      style: GoogleFonts.lunasima(
                                        fontSize: compact ? 12 : 17,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primary,
                                        height: 0.9,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'COUPON',
                                    style: GoogleFonts.lunasima(
                                      fontSize: compact ? 20 : 28,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                      height: 1,
                                    ),
                                  ),
                                  const Spacer(),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          formatCouponDate(coupon.endsAt),
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SvgPicture.asset(
                              coupon.isAnimeGoods
                                  ? 'assets/images/goods.svg'
                                  : 'assets/images/food.svg',
                              width: compact ? 42 : 70,
                              height: compact ? 60 : 82,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 36,
                  child: ColoredBox(
                    color: AppColors.primary,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${coupon.discountPercent}',
                                style: GoogleFonts.lusitana(
                                  color: Colors.white,
                                  fontSize: 58,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '%',
                                    style: GoogleFonts.lusitana(
                                      color: Colors.white,
                                      fontSize: 27,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'OFF',
                                    style: GoogleFonts.lusitana(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      height: 0.7,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(Icons.pets, color: Colors.white, size: 18),
            ),
            const Positioned(
              bottom: 8,
              right: 132,
              child: Icon(Icons.pets, color: Colors.white, size: 18),
            ),
            Positioned(
              right: -13,
              top: 62,
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            if (!coupon.unlocked)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.white.withValues(alpha: 0.7),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: AppRadius.brMd,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '訪問 ${coupon.visitedCount}/${coupon.totalSpotCount}・あと${coupon.remainingCount}か所',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                      borderRadius: AppRadius.brMd,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
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
    );
  }
}

class CouponHeroTicket extends StatelessWidget {
  const CouponHeroTicket({super.key, required this.coupon});

  final Coupon coupon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 18),
            child: Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${coupon.categoryLabel}\nCOUPON',
                      style: GoogleFonts.lunasima(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 0.85,
                      ),
                    ),
                  ),
                ),
                Text(
                  '${coupon.discountPercent}',
                  style: GoogleFonts.lusitana(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '%\nOFF',
                  style: GoogleFonts.lusitana(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 0.8,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Container(
              constraints: const BoxConstraints(minHeight: 190),
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          coupon.description ??
                              (coupon.isAnimeGoods
                                  ? '対象店舗のアニメグッズを${coupon.discountPercent}%OFFでご利用できます'
                                  : '${coupon.unlockSpotName ?? '対象店舗'}で${coupon.discountPercent}%OFFでご利用できます'),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          '有効期限\n${formatCouponDate(coupon.endsAt)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  SvgPicture.asset(
                    coupon.isAnimeGoods
                        ? 'assets/images/goods.svg'
                        : 'assets/images/food.svg',
                    width: 130,
                    height: 150,
                    fit: BoxFit.contain,
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
