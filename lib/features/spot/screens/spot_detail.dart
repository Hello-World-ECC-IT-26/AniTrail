import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/styles/app_dimens.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_bottom_action_bar.dart';
import '../../../core/widgets/main_buttom_nav.dart';
import '../../home/screens/home_screen.dart';
import '../../map/models/anime_spot.dart';
import '../../map/services/spot_api.dart';
import '../../shiori/models/shiori_draft.dart';
import '../../shiori/screens/shiori_list.dart';
import '../widgets/spot_comments_section.dart';

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
  SpotDetailPayload? _detail;

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
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final result = await _api.fetchSpotDetail(spot.spotId);
      if (mounted) {
        setState(() {
          _detail = result;
          _bookmarked = result.bookmarked;
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
    final userPhoto = _detail?.photoUrls.firstOrNull;
    if (userPhoto != null && userPhoto.isNotEmpty) return userPhoto;
    final proxyUrl = spot.streetViewProxyUrl;
    if (proxyUrl != null && proxyUrl.isNotEmpty) return proxyUrl;
    final imageUrl = spot.streetViewImageUrl;
    return imageUrl != null && imageUrl.isNotEmpty ? imageUrl : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                      left: AppSpacing.sm,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Center(
                      child: Text(spot.name, style: AppTextStyles.heading),
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
                      borderRadius: AppRadius.brSm,
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: _buildImage(),
                      ),
                    ),
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: AppCircleIconButton(
                        icon: _bookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_outline,
                        onTap: _bookmarkLoading ? null : _toggleBookmark,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── アニメタイトル ──
              Center(
                child: Text(
                  '「${widget.animeTitle}」',
                  style: AppTextStyles.subtitle,
                ),
              ),

              if (spot.sceneText.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Text(
                    spot.sceneText,
                    style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // ── 名称 ──
              Center(
                child: Text(
                  spot.name,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle,
                ),
              ),

              if (spot.addressText.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl,
                    ),
                    child: Text(
                      spot.addressText,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.label.copyWith(fontSize: 13),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // ── マップで確認 ──
              Center(
                child: AppButton(
                  label: 'マップで確認',
                  onPressed: _openMap,
                  icon: Icons.location_on_outlined,
                  fullWidth: false,
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _detail == null
                    ? const Center(child: CircularProgressIndicator())
                    : SpotCommentsSection(
                        spotId: spot.spotId,
                        initialDetail: _detail,
                      ),
              ),
            ],
          ),

          // ── 旅のしおりを確認（追加ボタンの上に固定） ──
          if (widget.showShioriActions)
            Positioned(
              left: AppSpacing.lg,
              bottom: 80,
              child: ValueListenableBuilder<List<Spot>>(
                valueListenable: _draft.spots,
                builder: (context, spots, child) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AppButton(
                        label: '旅のしおりを確認',
                        icon: Icons.location_on_outlined,
                        size: AppButtonSize.compact,
                        fullWidth: false,
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
                      ),
                      if (spots.isNotEmpty)
                        Positioned(
                          top: -AppSpacing.xs,
                          right: -AppSpacing.xs,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: AppColors.badge,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${spots.length}',
                              style: const TextStyle(
                                color: AppColors.white,
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
                builder: (context, spots, child) {
                  final added = _draft.contains(spot.spotId);
                  return AppBottomActionBar(
                    icon: added ? Icons.check : Icons.add,
                    label: added ? 'しおりに追加済み' : 'しおりに追加',
                    onPressed: () => _draft.toggle(_draftSpot),
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
            MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: index)),
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
        color: AppColors.placeholder,
        child: const Icon(Icons.image_outlined, color: AppColors.iconMuted),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: _authHeaders,
      fit: BoxFit.cover,
      placeholder: (context, imageUrl) =>
          Container(color: AppColors.placeholder),
      errorWidget: (context, imageUrl, error) => Container(
        color: AppColors.placeholder,
        child: const Icon(Icons.image_outlined, color: AppColors.iconMuted),
      ),
    );
  }
}
