import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/widgets/loading_screen.dart';
import '../../map/models/anime_spot.dart';
import '../../map/services/spot_api.dart';
import '../../search/widgets/search_result_card.dart';
import 'stamp_screen.dart';

/// 取得済みスタンプを、アニメ作品ごとにまとめて表示する一覧。
class AllStampCollectionsScreen extends StatefulWidget {
  final bool showBackButton;

  const AllStampCollectionsScreen({super.key, this.showBackButton = true});

  @override
  State<AllStampCollectionsScreen> createState() =>
      _AllStampCollectionsScreenState();
}

class _AllStampCollectionsScreenState extends State<AllStampCollectionsScreen> {
  final _api = SpotApi();
  late final Future<List<_AnimeCollectionSummary>> _collectionsFuture;

  @override
  void initState() {
    super.initState();
    _collectionsFuture = _loadCollections();
  }

  Future<List<_AnimeCollectionSummary>> _loadCollections() async {
    final cardCollections = await _api.fetchStampCollections();
    final collections = <String, _AnimeCollectionSummary>{};

    for (final item in cardCollections) {
      for (final spot in item.card.spots) {
        final stats = item.visitStats[spot.spotId];
        final animeTitle = spot.animeTitle ?? item.card.title;
        final key = spot.animeId ?? animeTitle;
        final collection = collections.putIfAbsent(
          key,
          () =>
              _AnimeCollectionSummary(animeId: spot.animeId, title: animeTitle),
        );
        collection.addSpot(spot, stats);
      }
    }

    final obtainedCollections = collections.values
        .where((collection) => collection.obtainedCount > 0)
        .toList();
    obtainedCollections.sort((a, b) {
      final aVisitedAt = a.lastVisitedAt;
      final bVisitedAt = b.lastVisitedAt;
      if (aVisitedAt != null && bVisitedAt != null) {
        return bVisitedAt.compareTo(aVisitedAt);
      }
      if (aVisitedAt != null) return -1;
      if (bVisitedAt != null) return 1;
      return a.title.compareTo(b.title);
    });
    return obtainedCollections;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FC),
      body: SafeArea(
        child: FutureBuilder<List<_AnimeCollectionSummary>>(
          future: _collectionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AppLoadingScreen(message: 'コレクションを読み込んでいます・・・');
            }
            if (snapshot.hasError) {
              return _buildMessage('コレクションを読み込めませんでした');
            }
            final collections = snapshot.data ?? [];
            if (collections.isEmpty) {
              return _buildMessage('まだ獲得したスタンプがありません');
            }
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Row(
                      children: [
                        if (widget.showBackButton) ...[
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                        ] else
                          const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '全てのコレクション',
                                style: AppTextStyles.title.copyWith(
                                  color: const Color(0xFF12265A),
                                  fontSize: 28,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '獲得したアニメ ${collections.length}作品',
                                style: AppTextStyles.bodySecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: collections.length,
                    itemBuilder: (context, index) =>
                        _buildCollectionTile(collections[index]),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessage(String message) {
    return Column(
      children: [
        if (widget.showBackButton)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        Expanded(
          child: Center(child: Text(message, style: AppTextStyles.body)),
        ),
      ],
    );
  }

  Widget _buildCollectionTile(_AnimeCollectionSummary collection) {
    return SearchResultCard(
      title: collection.title,
      bannerImage: collection.keyVisualUrl,
      spotCount: collection.totalCount,
      spotImages: collection.thumbnailUrls,
      httpHeaders: _authHeaders,
      actionLabel: '詳細を見る',
      thumbnailCount: 3,
      onViewSpots: () => _openCollection(collection),
    );
  }

  Map<String, String> get _authHeaders {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return token == null ? const {} : {'Authorization': 'Bearer $token'};
  }

  void _openCollection(_AnimeCollectionSummary collection) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StampScreen(
          animeId: collection.animeId,
          animeTitle: collection.title,
          showBackButton: true,
        ),
      ),
    );
  }
}

class _AnimeCollectionSummary {
  final String? animeId;
  final String title;
  final Map<String, Spot> _spots = {};
  final Map<String, StampVisitStats> _visitStats = {};

  _AnimeCollectionSummary({required this.animeId, required this.title});

  int get totalCount => _spots.length;
  int get obtainedCount => _visitStats.length;
  String? get keyVisualUrl => _spots.values
      .map((spot) => spot.keyVisualUrl)
      .whereType<String>()
      .cast<String?>()
      .firstOrNull;

  List<String> get thumbnailUrls {
    final urls = <String>{};
    for (final spot in _spots.values) {
      urls.addAll(_visitStats[spot.spotId]?.arrivalPhotoUrls ?? const []);
      final image = spot.image;
      if (image != null && image.isNotEmpty) urls.add(image);
      final streetView = spot.streetViewProxyUrl ?? spot.streetViewImageUrl;
      if (streetView != null && streetView.isNotEmpty) urls.add(streetView);
    }
    return urls.take(3).toList();
  }

  DateTime? get lastVisitedAt {
    DateTime? latest;
    for (final stats in _visitStats.values) {
      final visitedAt = stats.lastVisitedAt;
      if (visitedAt != null && (latest == null || visitedAt.isAfter(latest))) {
        latest = visitedAt;
      }
    }
    return latest;
  }

  void addSpot(Spot spot, StampVisitStats? stats) {
    _spots.putIfAbsent(spot.spotId, () => spot);
    if (stats == null || stats.count == 0) return;

    final current = _visitStats[spot.spotId];
    final currentDate = current?.lastVisitedAt;
    final incomingDate = stats.lastVisitedAt;
    _visitStats[spot.spotId] = StampVisitStats(
      count: (current?.count ?? 0) + stats.count,
      lastVisitedAt: currentDate == null
          ? incomingDate
          : incomingDate == null || currentDate.isAfter(incomingDate)
          ? currentDate
          : incomingDate,
      arrivalPhotoUrls: {
        ...?current?.arrivalPhotoUrls,
        ...stats.arrivalPhotoUrls,
      }.toList(),
    );
  }
}
