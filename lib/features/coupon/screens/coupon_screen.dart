import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/widgets/loading_screen.dart';
import '../data/coupon_repository.dart';
import '../models/coupon.dart';
import '../widgets/coupon_detail.dart';
import '../widgets/coupon_ticket.dart';

class CouponScreen extends StatefulWidget {
  const CouponScreen({super.key});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<CouponRepository>().load().catchError((_) {}));
    });
  }

  Future<void> _showSortSheet(CouponRepository repository) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('並び替え', style: AppTextStyles.subtitle),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              _option(
                label: '新着順',
                selected: repository.sort == CouponSort.newest,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await repository.setSort(CouponSort.newest);
                },
              ),
              const Divider(),
              _option(
                label: '有効期限順',
                selected: repository.sort == CouponSort.expires,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await repository.setSort(CouponSort.expires);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('絞り込み', style: AppTextStyles.subtitle),
              const Divider(),
              _option(
                label: 'すべて',
                selected: repository.category == null,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await repository.setCategory(null);
                },
              ),
              const Divider(),
              _option(
                label: 'ドリンク&フード',
                selected: repository.category == CouponCategory.drinkFood,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await repository.setCategory(CouponCategory.drinkFood);
                },
              ),
              const Divider(),
              _option(
                label: 'アニメグッズ',
                selected: repository.category == CouponCategory.animeGoods,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await repository.setCategory(CouponCategory.animeGoods);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option({
    required String label,
    required bool selected,
    required Future<void> Function() onTap,
  }) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
    title: Text(label),
    trailing: selected
        ? const Icon(Icons.check, color: AppColors.primary)
        : null,
    onTap: () => unawaited(onTap().catchError((_) {})),
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<CouponRepository>(
      builder: (context, repository, _) {
        if (repository.loading && !repository.initialized) {
          return const AppLoadingScreen(message: 'クーポンを読み込んでいます・・・');
        }
        if (repository.error != null && !repository.initialized) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('クーポンを読み込めませんでした'),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: repository.loading
                        ? null
                        : () => unawaited(
                            repository.load(refresh: true).catchError((_) {}),
                          ),
                    child: const Text('再試行'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('クーポン一覧', style: AppTextStyles.title),
            ),
            const Divider(indent: 16, endIndent: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: repository.loading
                    ? null
                    : () => _showSortSheet(repository),
                icon: const Icon(Icons.sort, size: 18),
                label: Text(
                  repository.sort == CouponSort.newest ? '新着順' : '有効期限順',
                ),
              ),
            ),
            Expanded(
              child: repository.coupons.isEmpty
                  ? const Center(child: Text('表示できるクーポンはありません'))
                  : RefreshIndicator(
                      onRefresh: () => repository.load(refresh: true),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: repository.coupons.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 18),
                        itemBuilder: (context, index) {
                          final coupon = repository.coupons[index];
                          return Semantics(
                            button: true,
                            label:
                                '${coupon.title} ${coupon.discountPercent}%オフ',
                            child: InkWell(
                              onTap: () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CouponDetailScreen(coupon: coupon),
                                ),
                              ),
                              child: CouponTicketCard(coupon: coupon),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
