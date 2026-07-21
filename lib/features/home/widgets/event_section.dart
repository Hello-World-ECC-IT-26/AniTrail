import 'dart:async';

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
        SizedBox(height: 160, child: _EventCarousel(events: events)),
      ],
    );
  }
}

class _EventCarousel extends StatefulWidget {
  const _EventCarousel({required this.events});

  final List<AppEvent> events;

  @override
  State<_EventCarousel> createState() => _EventCarouselState();
}

class _EventCarouselState extends State<_EventCarousel> {
  static const _autoScrollInterval = Duration(seconds: 4);
  static const _autoScrollDuration = Duration(milliseconds: 700);

  final PageController _controller = PageController();
  final Set<String> _precacheRequestedUrls = {};
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheBannerImages();
  }

  @override
  void didUpdateWidget(covariant _EventCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events.length != widget.events.length) {
      if (_controller.hasClients &&
          (_controller.page?.round() ?? 0) >= widget.events.length) {
        _controller.jumpToPage(0);
      }
      _startAutoScroll();
    }
    _precacheBannerImages();
  }

  void _precacheBannerImages() {
    for (final event in widget.events) {
      final bannerUrl = event.bannerUrl?.trim();
      if (bannerUrl == null ||
          bannerUrl.isEmpty ||
          !_precacheRequestedUrls.add(bannerUrl)) {
        continue;
      }

      unawaited(
        precacheImage(
          CachedNetworkImageProvider(bannerUrl),
          context,
        ).catchError((Object error, StackTrace stackTrace) {}),
      );
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (widget.events.length < 2) return;

    _autoScrollTimer = Timer.periodic(_autoScrollInterval, (_) {
      if (!_controller.hasClients) return;

      final currentPage = _controller.page?.round() ?? 0;
      final nextPage = (currentPage + 1) % widget.events.length;
      _controller.animateToPage(
        nextPage,
        duration: _autoScrollDuration,
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _pauseAutoScroll(PointerDownEvent event) {
    _autoScrollTimer?.cancel();
  }

  void _resumeAutoScroll(PointerEvent event) {
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _pauseAutoScroll,
      onPointerUp: _resumeAutoScroll,
      onPointerCancel: _resumeAutoScroll,
      child: PageView.builder(
        controller: _controller,
        physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
        itemCount: widget.events.length,
        itemBuilder: (context, index) =>
            Center(child: _EventBanner(event: widget.events[index])),
      ),
    );
  }
}

class _EventBanner extends StatefulWidget {
  const _EventBanner({required this.event});

  final AppEvent event;

  @override
  State<_EventBanner> createState() => _EventBannerState();
}

class _EventBannerState extends State<_EventBanner>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bannerUrl = widget.event.bannerUrl?.trim();
    return SizedBox(
      width: 300,
      child: Material(
        color: AppColors.primary,
        borderRadius: AppRadius.brSm,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(event: widget.event),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bannerUrl != null && bannerUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: bannerUrl,
                  fit: BoxFit.cover,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  useOldImageOnUrlChange: true,
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
                      widget.event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      formatEventPeriod(widget.event),
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
