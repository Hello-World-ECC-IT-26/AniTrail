import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/styles/app_styles.dart';
import '../../map/models/anime_spot.dart';
import '../../map/services/spot_api.dart';
import '../../shiori/screens/shiori_detail.dart';

class StampCardSection extends StatefulWidget {
  const StampCardSection({super.key});

  @override
  State<StampCardSection> createState() => _StampCardSectionState();
}

class _StampCardSectionState extends State<StampCardSection> {
  final SpotApi _api = SpotApi();

  List<StampCard> _cards = [];
  bool _loading = true;

  // 開いているカードのindex（nullなら全部閉じ）
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cards = await _api.fetchStampCards();
      if (mounted)
        setState(() {
          _cards = cards;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, String> get _authHeaders {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return token != null ? {'Authorization': 'Bearer $token'} : {};
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '作成した旅のしおり',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        if (_loading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_cards.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'まだ旅のしおりがありません',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double cardHeight = 130;
                const double peekHeight = 100.0;
                const double expandedExtra = 120.0;

                final expandedIndex = _expandedIndex;
                double totalHeight =
                    cardHeight +
                    (_cards.length - 1) * peekHeight +
                    (expandedIndex != null ? expandedExtra : 0);

                return SizedBox(
                  height: totalHeight,
                  child: Stack(
                    children: List.generate(_cards.length, (index) {
                      final card = _cards[index];
                      final isExpanded = _expandedIndex == index;

                      double topOffset = index * peekHeight;
                      if (expandedIndex != null && index > expandedIndex) {
                        topOffset += expandedExtra;
                      }

                      return Positioned(
                        top: topOffset,
                        left: 0,
                        right: 0,
                        child: _ShioriCard(
                          title: card.title,
                          spotCount: card.spotCount,
                          spotImages: card.spotImageUrls,
                          authHeaders: _authHeaders,
                          isExpanded: isExpanded,
                          onTap: () {
                            setState(() {
                              _expandedIndex = isExpanded ? null : index;
                            });
                          },
                          onViewDetail: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ShioriDetailScreen(cardId: card.cardId),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 24),
      ],
    );
  }
}

/// 個別しおりカード（アコーディオン）
class _ShioriCard extends StatelessWidget {
  final String title;
  final int spotCount;
  final List<String> spotImages;
  final Map<String, String> authHeaders;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onViewDetail;

  const _ShioriCard({
    required this.title,
    required this.spotCount,
    required this.spotImages,
    required this.authHeaders,
    required this.isExpanded,
    required this.onTap,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildBanner(),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 280),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: _buildExpandedContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    final bannerUrl = spotImages.isNotEmpty ? spotImages.first : null;
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
        bottomLeft: Radius.circular(isExpanded ? 0 : 16),
        bottomRight: Radius.circular(isExpanded ? 0 : 16),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 130,
        child: Stack(
          fit: StackFit.expand,
          children: [
            bannerUrl != null
                ? CachedNetworkImage(
                    imageUrl: bannerUrl,
                    httpHeaders: authHeaders,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) =>
                        Container(color: AppColors.primary),
                  )
                : Container(color: AppColors.primary),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white70,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '聖地 $spotCount箇所',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 12,
              child: AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 280),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          ...List.generate(4, (index) {
            final hasImage = index < spotImages.length;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: spotImages[index],
                          httpHeaders: authHeaders,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) =>
                              Container(color: Colors.grey.shade300),
                        )
                      : Container(color: Colors.grey.shade300),
                ),
              ),
            );
          }),
          const Spacer(),
          ElevatedButton(
            onPressed: onViewDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              '詳細を見る',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
