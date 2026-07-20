import 'package:flutter/material.dart';

import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../models/coupon.dart';

Future<bool> showCouponGrantDialog(
  BuildContext context,
  List<CouponGrant> grants,
) async {
  if (grants.isEmpty) return false;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _CouponGrantDialog(grants: grants),
      ) ??
      false;
}

class _CouponGrantDialog extends StatelessWidget {
  const _CouponGrantDialog({required this.grants});

  final List<CouponGrant> grants;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      title: Row(
        children: [
          const Icon(Icons.confirmation_number, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              grants.length == 1 ? 'クーポン獲得！' : '${grants.length}枚のクーポンを獲得！',
              style: AppTextStyles.heading,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('聖地の訪問条件を達成しました。'),
            const SizedBox(height: AppSpacing.md),
            ...grants.map(
              (grant) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Text(
                    '${grant.title}　${grant.discountPercent}% OFF',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('閉じる'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(grants.length == 1 ? '詳細を見る' : 'クーポンを見る'),
        ),
      ],
    );
  }
}
