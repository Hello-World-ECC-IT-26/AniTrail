import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/widgets/app_bar.dart';
import '../models/app_event.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.event});

  final AppEvent event;

  @override
  Widget build(BuildContext context) {
    final bannerUrl = event.bannerUrl?.trim();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AniTrailAppBar(showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bannerUrl != null && bannerUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: bannerUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, _, _) => const _BannerLoadError(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          formatEventPeriod(event),
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                  if (event.summary?.trim().isNotEmpty ?? false) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(event.summary!.trim(), style: AppTextStyles.subtitle),
                  ],
                  if (event.content?.trim().isNotEmpty ?? false) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      event.content!.trim(),
                      style: AppTextStyles.body.copyWith(height: 1.7),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerLoadError extends StatelessWidget {
  const _BannerLoadError();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: AppColors.iconMuted),
            SizedBox(height: AppSpacing.xs),
            Text('画像を読み込めませんでした', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
