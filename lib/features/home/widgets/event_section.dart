import 'package:flutter/material.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/styles/app_dimens.dart';

class EventSection extends StatelessWidget {
  const EventSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            '期間限定イベント開催中！',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 300,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(color: AppColors.primary),

                child: const Center(
                  child: Text('イベント', style: TextStyle(color: AppColors.white)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
