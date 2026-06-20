import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/styles/app_styles.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/main_buttom_nav.dart';
import '../../home/screens/home_screen.dart';
import '../../map/models/anime_spot.dart';
import '../../map/services/spot_api.dart';
import '../../shiori/models/shiori_draft.dart';
import '../../shiori/screens/shiori_list.dart';

/// 聖地詳細画面。画像・アニメ情報・住所を表示し、しおりに追加できる。
class SpotDetailScreen extends StatefulWidget {
  final Spot spot;
  final String animeTitle;
  final String? keyVisualUrl;
  final bool showShioriActions;

  const SpotDetailScreen({
    super.key,
    required this.spot,
    required this.animeTitle,
    this.keyVisualUrl,
    this.showShioriActions = true,
  });

  @override
  State<SpotDetailScreen> createState() => _SpotDetailScreenState();
}

class _SpotDetailScreenState extends State<SpotDetailScreen> {
  final SpotApi _api = SpotApi();
  final ShioriDraft _draft = ShioriDraft.instance;

  bool _bookmarked = false;
  bool _bookmarkLoading = true;

  Spot get spot => widget.spot;
  Spot get _draftSpot => spot.withAnime(
    animeId: spot.animeId ?? '',
    animeTitle: spot.animeTitle ?? widget.animeTitle,
    keyVisualUrl: spot.keyVisualUrl ?? widget.keyVisualUrl,
  );

  Map<String, String> get _authHeaders {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return token != null ? {'Authorization': 'Bearer $token'} : {};
  }

  @override
  void initState() {
    super.initState();
    _loadBookmark();
  }

  Future<void> _loadBookmark() async {
    try {
      final result = await _api.isBookmarked(spot.spotId);
      if (mounted) {
        setState(() {
          _bookmarked = result;
          _bookmarkLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _bookmarkLoading = false);
    }
  }

  Future<void> _toggleBookmark() async {
    final was = _bookmarked;
    setState(() => _bookmarked = !was);
    try {
      was
          ? await _api.removeBookmark(spot.spotId)
          : await _api.addBookmark(spot.spotId);
    } catch (_) {
      if (mounted) setState(() => _bookmarked = was);
    }
  }

  Future<void> _openMap() async {
    final lat = spot.latitude;
    final lng = spot.longitude;
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('位置情報がありません')));
      return;
    }
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String? get _imageUrl {
    final proxyUrl = spot.streetViewProxyUrl;
    if (proxyUrl != null && proxyUrl.isNotEmpty) return proxyUrl;
    final imageUrl = spot.streetViewImageUrl;
    return imageUrl != null && imageUrl.isNotEmpty ? imageUrl : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AniTrailAppBar(),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(
              0,
              0,
              0,
              widget.showShioriActions ? 170 : 24,
            ),
            children: [
              // ── 戻る + タイトル ──
              SizedBox(
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 8,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Center(
                      child: Text(
                        spot.name,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── メイン画像 + ブックマーク ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: 16 / 11,
                        child: _buildImage(),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: _bookmarkLoading ? null : _toggleBookmark,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _bookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_outline,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── アニメタイトル ──
              Center(
                child: Text(
                  '「${widget.animeTitle}」',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              if (spot.sceneText.isNotEmpty) ...[
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    spot.sceneText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ── 名称 ──
              Center(
                child: Text(
                  spot.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              if (spot.addressText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      spot.addressText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── マップで確認 ──
              Center(
                child: ElevatedButton.icon(
                  onPressed: _openMap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.location_on_outlined, size: 18),
                  label: const Text(
                    'マップで確認',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),

          // ── 旅のしおりを確認（追加ボタンの上に固定） ──
          if (widget.showShioriActions)
            Positioned(
              left: 16,
              bottom: 80,
              child: ValueListenableBuilder<List<Spot>>(
                valueListenable: _draft.spots,
                builder: (context, spots, __) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ElevatedButton.icon(
                        onPressed: spots.isEmpty
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ShioriListScreen(
                                      spots: List.from(spots),
                                    ),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10357A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.location_on_outlined, size: 18),
                        label: const Text(
                          '旅のしおりを確認',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (spots.isNotEmpty)
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
                            alignment: Alignment.center,
                            child: Text(
                              '${spots.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

          // ── しおりに追加（下部固定） ──
          if (widget.showShioriActions)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<List<Spot>>(
                valueListenable: _draft.spots,
                builder: (context, _, __) {
                  final added = _draft.contains(spot.spotId);
                  return Container(
                    color: const Color(0xFF10357A),
                    child: TextButton.icon(
                      onPressed: () => _draft.toggle(_draftSpot),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                      icon: Icon(
                        added ? Icons.check : Icons.add,
                        color: Colors.white,
                      ),
                      label: Text(
                        added ? 'しおりに追加済み' : 'しおりに追加',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),

      bottomNavigationBar: MainBottomNav(
        onTap: (index) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(initialIndex: index),
            ),
            (route) => false,
          );
        },
      ),
    );
  }

  Widget _buildImage() {
    final url = _imageUrl;
    if (url == null || url.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.image_outlined, color: Colors.grey.shade400),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: _authHeaders,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: Colors.grey.shade200),
      errorWidget: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.image_outlined, color: Colors.grey.shade400),
      ),
    );
  }
}
