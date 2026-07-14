import 'package:flutter/material.dart';

import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/widgets/loading_screen.dart';
import '../../map/models/anime_spot.dart';
import '../../map/services/spot_api.dart';
import '../widgets/stamp_badge.dart';
import 'all_stamp_collections_screen.dart';
import 'stamp_collection_detail_screen.dart';

class StampScreen extends StatefulWidget {
  final String? cardId;
  final String? animeId;
  final String? animeTitle;
  final String? recentlyObtainedSpotId;
  final bool showBackButton;

  const StampScreen({
    super.key,
    this.cardId,
    this.animeId,
    this.animeTitle,
    this.recentlyObtainedSpotId,
    this.showBackButton = false,
  });

  @override
  State<StampScreen> createState() => _StampScreenState();
}

class _StampScreenState extends State<StampScreen> {
  final _api = SpotApi();
  late final Future<List<_StampCollection>> _collectionsFuture;

  @override
  void initState() {
    super.initState();
    _collectionsFuture = _loadCollections();
  }

  Future<List<_StampCollection>> _loadCollections() async {
    final cards = widget.cardId == null
        ? await _api.fetchStampCards()
        : [await _api.fetchStampCard(widget.cardId!)];
    final collections = <String, _StampCollection>{};

    for (final card in cards) {
      final full = card.spots.isNotEmpty
          ? card
          : await _api.fetchStampCard(card.cardId);
      final visitStats = await _api.fetchStampVisitStats(card.cardId);

      for (final spot in full.spots) {
        final animeTitle = spot.animeTitle ?? full.title;
        final matchesAnime = widget.animeId != null
            ? spot.animeId == widget.animeId
            : widget.animeTitle == null || animeTitle == widget.animeTitle;
        if (!matchesAnime) continue;
        final key = spot.animeId ?? animeTitle;
        final collection = collections.putIfAbsent(
          key,
          () => _StampCollection(title: animeTitle),
        );
        var stats = visitStats[spot.spotId];
        if (stats == null && spot.spotId == widget.recentlyObtainedSpotId) {
          stats = StampVisitStats(count: 1, lastVisitedAt: DateTime.now());
        }
        collection.addSpot(spot, stats);
      }
    }

    final list = collections.values.toList();
    list.sort((a, b) => a.title.compareTo(b.title));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<List<_StampCollection>>(
          future: _collectionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AppLoadingScreen(message: 'スタンプを読み込んでいます・・・');
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('コレクションを読み込めませんでした', style: AppTextStyles.body),
              );
            }
            final collections = snapshot.data ?? [];
            if (collections.isEmpty) {
              return Center(
                child: Text('まだコレクションがありません', style: AppTextStyles.body),
              );
            }
            final showPageBackButton =
                widget.cardId != null || widget.showBackButton;
            return Column(
              children: [
                if (showPageBackButton)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      showPageBackButton ? 0 : AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    itemCount: collections.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.lg),
                    itemBuilder: (context, index) =>
                        _buildCollectionCard(collections[index]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCollectionCard(_StampCollection collection) {
    final total = collection.spots.length;
    final obtained = collection.obtainedSpots.length;
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 132,
                top: AppSpacing.xl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title.copyWith(
                        color: const Color(0xFF12265A),
                        fontSize: 30,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '$obtained/$total',
                      style: AppTextStyles.heading.copyWith(
                        color: const Color(0xFF12265A),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: -8,
                bottom: -8,
                child: Image.asset(
                  'assets/images/weasel02.png',
                  width: 145,
                  height: 170,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xxl,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F8FC),
            borderRadius: AppRadius.brLg,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.lg,
                  childAspectRatio: 0.78,
                ),
                itemCount: total,
                itemBuilder: (context, index) {
                  final spot = collection.spots[index];
                  final obtained = collection.obtainedSpotIds.contains(
                    spot.spotId,
                  );
                  return _buildStampItem(
                    collection: collection,
                    spot: spot,
                    index: index,
                    obtained: obtained,
                  );
                },
              ),
            ],
          ),
        ),
        if (widget.cardId != null) ...[
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: 300,
            height: AppSizes.buttonHeight,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AllStampCollectionsScreen(),
                  ),
                );
              },
              child: const Text('全てのコレクションを見る'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStampItem({
    required _StampCollection collection,
    required Spot spot,
    required int index,
    required bool obtained,
  }) {
    return InkWell(
      borderRadius: AppRadius.brSm,
      onTap: obtained
          ? () {
              showDialog<void>(
                context: context,
                barrierColor: AppColors.black.withValues(alpha: 0.45),
                builder: (_) => StampCollectionDetailDialog(
                  spot: spot,
                  animeTitle: collection.title,
                  stampIndex: index + 1,
                  stampTotal: collection.spots.length,
                  imageUrl: spot.streetViewProxyUrl ?? spot.streetViewImageUrl,
                  arrivalPhotoUrls:
                      collection.visitStats[spot.spotId]?.arrivalPhotoUrls,
                  visitCount: collection.visitStats[spot.spotId]?.count ?? 0,
                  obtainedAt: collection.visitStats[spot.spotId]?.lastVisitedAt,
                ),
              );
            }
          : null,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: obtained
                ? StampBadge(label: spot.name)
                : const LockedStampBadge(),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${index + 1}'.padLeft(2, '0'),
            style: AppTextStyles.caption.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _StampCollection {
  final String title;
  final List<Spot> spots = [];
  final Set<String> obtainedSpotIds = {};
  final Map<String, StampVisitStats> visitStats = {};

  _StampCollection({required this.title});

  List<Spot> get obtainedSpots =>
      spots.where((spot) => obtainedSpotIds.contains(spot.spotId)).toList();

  void addSpot(Spot spot, StampVisitStats? stats) {
    if (spots.any((item) => item.spotId == spot.spotId)) {
      if (stats != null) _mergeStats(spot.spotId, stats);
      return;
    }
    spots.add(spot);
    if (stats != null) _mergeStats(spot.spotId, stats);
  }

  void _mergeStats(String spotId, StampVisitStats incoming) {
    final current = visitStats[spotId];
    final currentDate = current?.lastVisitedAt;
    final incomingDate = incoming.lastVisitedAt;
    final latest = currentDate == null
        ? incomingDate
        : incomingDate == null || currentDate.isAfter(incomingDate)
        ? currentDate
        : incomingDate;
    visitStats[spotId] = StampVisitStats(
      count: (current?.count ?? 0) + incoming.count,
      lastVisitedAt: latest,
      arrivalPhotoUrls: {
        ...?current?.arrivalPhotoUrls,
        ...incoming.arrivalPhotoUrls,
      }.toList(),
    );
    obtainedSpotIds.add(spotId);
  }
}
