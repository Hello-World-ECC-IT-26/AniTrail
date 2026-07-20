import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/data/app_data_repository.dart';
import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../models/app_event.dart';
import '../screens/event_detail_screen.dart';

class EventSection extends StatelessWidget {
  const EventSection({super.key});

  @override
  Widget build(BuildContext context) {
    final events = context.watch<AppDataRepository>().activeEvents;
    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        const SizedBox(
          width: double.infinity,
          child: Text(
            '期間限定イベント開催中！',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) => _EventBanner(event: events[index]),
          ),
        ),
      ],
    );
  }
}

class _EventBanner extends StatelessWidget {
  const _EventBanner({required this.event});

  final AppEvent event;

  @override
  Widget build(BuildContext context) {
    final bannerUrl = event.bannerUrl?.trim();
    return SizedBox(
      width: 300,
      child: Material(
        color: AppColors.primary,
        borderRadius: AppRadius.brSm,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bannerUrl != null && bannerUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: bannerUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.white,
                    ),
                  ),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                    stops: [0.35, 1],
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      formatEventPeriod(event),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
