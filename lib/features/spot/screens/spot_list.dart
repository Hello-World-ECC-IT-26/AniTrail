import 'package:AniTrail/features/home/screens/home_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/widgets/main_buttom_nav.dart';
import '../../map/models/anime_spot.dart';
import '../../map/services/spot_api.dart';
import '../../shiori/models/shiori_draft.dart';
import '../../shiori/screens/shiori_list.dart';
import 'spot_detail.dart';

class SpotList extends StatefulWidget {
  final String animeId;
  final String animeTitle;

  /// アニメのキービジュアルURL（バナー・network画像）
  final String? bannerImageUrl;
  final int spotCount;

  const SpotList({
    super.key,
    required this.animeId,
    required this.animeTitle,
    this.bannerImageUrl,
    this.spotCount = 10,
  });

  @override
  State<SpotList> createState() => _SpotListState();
}

class _SpotListState extends State<SpotList> {
  final SpotApi _api = SpotApi();

  final ShioriDraft _draft = ShioriDraft.instance;

  List<Spot> _spots = [];
  bool _loading = true;
  String? _error;

  // ブックマーク済みの聖地（spot_id）
  final Set<String> _bookmarked = {};

  Map<String, String> get _authHeaders {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return token != null ? {'Authorization': 'Bearer $token'} : {};
  }

  @override
  void initState() {
    super.initState();
    _loadSpots();
    _draft.spots.addListener(_onDraftChanged);
  }

  @override
  void dispose() {
    _draft.spots.removeListener(_onDraftChanged);
    super.dispose();
  }

  void _onDraftChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSpots() async {
    try {
      final spots = await _api.fetchSpots(widget.animeId);
      if (!mounted) return;
      setState(() {
        _spots = spots
            .map(
              (spot) => spot.withAnime(
                animeId: widget.animeId,
                animeTitle: widget.animeTitle,
                keyVisualUrl: widget.bannerImageUrl,
              ),
            )
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '聖地の取得に失敗しました。';
      });
    }
  }

  void _toggleSelect(Spot spot) {
    _draft.toggle(spot); // リスナー経由で再描画
  }

  void _openDetail(Spot spot) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SpotDetailScreen(
          spot: spot,
          animeTitle: widget.animeTitle,
          keyVisualUrl: widget.bannerImageUrl,
        ),
      ),
    );
  }

  Future<void> _toggleBookmark(String spotId) async {
    final wasBookmarked = _bookmarked.contains(spotId);
    setState(() {
      wasBookmarked ? _bookmarked.remove(spotId) : _bookmarked.add(spotId);
    });
    try {
      if (wasBookmarked) {
        await _api.removeBookmark(spotId);
      } else {
        await _api.addBookmark(spotId);
      }
    } catch (_) {
      // 失敗したら元に戻す
      if (!mounted) return;
      setState(() {
        wasBookmarked ? _bookmarked.add(spotId) : _bookmarked.remove(spotId);
      });
    }
  }

  void _createShiori() {
    final selected = List<Spot>.from(_draft.spots.value);
    if (selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('聖地を「+追加」してから作成してください')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ShioriListScreen(spots: selected)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                )
              else if (_spots.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      '聖地が登録されていません',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildSpotCard(_spots[index]),
                      ),
                      childCount: _spots.length,
                    ),
                  ),
                ),
            ],
          ),

          // ── 旅のしおりを作成ボタン（左下固定） ─────
          Positioned(
            left: 16,
            bottom: 10,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ElevatedButton.icon(
                  onPressed: _createShiori,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10357A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.location_on_outlined, size: 18),
                  label: const Text(
                    '旅のしおりを作成',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),

                // バッジ（選択数）
                if (_draft.spots.value.isNotEmpty)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${_draft.spots.value.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: MainBottomNav(
        onTap: (index) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        },
      ),
    );
  }

  // ── アニメバナーヘッダー ────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Stack(
              fit: StackFit.expand,
              children: [
                widget.bannerImageUrl != null &&
                        widget.bannerImageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.bannerImageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _bannerPlaceholder(),
                      )
                    : _bannerPlaceholder(),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: [0, 0.55, 1],
                      colors: [
                        Color(0xB34A76E8),
                        Color(0x80745FC6),
                        Color(0x33745FC6),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.animeTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black)],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '聖地 ${widget.spotCount}箇所',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bannerPlaceholder() => Container(
    color: AppColors.primary,
    child: const Icon(Icons.movie_outlined, color: Colors.white54, size: 56),
  );

  // ── 聖地サムネイル（実写真→Street View→プレースホルダ） ──
  Widget _buildThumbnail(Spot spot) {
    final image = spot.image;
    if (image != null && image.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: image,
        fit: BoxFit.cover,
        placeholder: (_, __) => _placeholderImage(),
        errorWidget: (_, __, ___) => _streetViewOrPlaceholder(spot),
      );
    }
    return _streetViewOrPlaceholder(spot);
  }

  Widget _streetViewOrPlaceholder(Spot spot) {
    final url = spot.streetViewProxyUrl ?? spot.streetViewImageUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        httpHeaders: _authHeaders,
        fit: BoxFit.cover,
        placeholder: (_, __) => _placeholderImage(),
        errorWidget: (_, __, ___) => _placeholderImage(),
      );
    }
    return _placeholderImage();
  }

  Widget _placeholderImage() => Container(
    color: Colors.grey.shade200,
    child: Icon(Icons.image_outlined, color: Colors.grey.shade400),
  );

  // ── 聖地カード1枚 ───────────────────────────────────
  Widget _buildSpotCard(Spot spot) {
    final isBookmarked = _bookmarked.contains(spot.spotId);
    final isSelected = _draft.contains(spot.spotId);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── サムネイル + ブックマーク ──────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 150,
                  height: 130,
                  child: _buildThumbnail(spot),
                ),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: GestureDetector(
                  onTap: () => _toggleBookmark(spot.spotId),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── テキスト情報 ──────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spot.animeTitle ?? widget.animeTitle,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // 場所名
                  Text(
                    spot.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // 住所
                  Text(
                    spot.addressText,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _toggleSelect(spot),
                        icon: Icon(
                          isSelected ? Icons.check : Icons.add,
                          size: 14,
                          color: isSelected ? AppColors.primary : Colors.black,
                        ),
                        label: Text(
                          isSelected ? '追加済み' : '追加',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.black,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _openDetail(spot),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('詳細', style: TextStyle(fontSize: 14)),
                      ),
                    ],
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
