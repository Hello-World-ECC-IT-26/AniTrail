import 'package:AniTrail/features/home/screens/home_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/widgets/main_buttom_nav.dart';
import '../../../core/widgets/app_bar.dart';
import '../../map/models/anime_spot.dart';
import '../../spot/screens/spot_detail.dart';
import '../widgets/loading.dart';

class ShioriListScreen extends StatefulWidget {
  /// 追加済み聖地リスト（spot_listから受け取る）
  final List<Spot> spots;

  const ShioriListScreen({super.key, this.spots = const []});

  @override
  State<ShioriListScreen> createState() => _ShioriListScreenState();
}

class _ShioriListScreenState extends State<ShioriListScreen> {
  // 編集可能な聖地リスト
  late List<Spot> _spots;
  final TextEditingController _titleController = TextEditingController();

  Map<String, String> get _authHeaders {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return token != null ? {'Authorization': 'Bearer $token'} : {};
  }

  @override
  void initState() {
    super.initState();
    _spots = List.from(widget.spots);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _deleteSpot(int index) {
    setState(() => _spots.removeAt(index));
  }

  void _openDetail(Spot spot) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SpotDetailScreen(
          spot: spot,
          animeTitle: spot.animeTitle ?? '',
          keyVisualUrl: spot.keyVisualUrl,
          showShioriActions: false,
        ),
      ),
    );
  }

  void _create() {
    if (_spots.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('聖地が1つもありません')));
      return;
    }
    final title = _titleController.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatingShioriScreen(
          title: title.isEmpty ? null : title,
          spots: List.from(_spots),
          spotIds: _spots.map((s) => s.spotId).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AniTrailAppBar(),
      body: Stack(
        children: [
          // ── HEADER (back button custom) ──
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 8,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Center(
                    child: Text(
                      '旅のしおり',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── LIST CONTENT ──
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                // ── しおりタイトル入力 ───────────────
                TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'しおりタイトル（任意）',
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 16),

                if (_animeVisualSpots.isNotEmpty) ...[
                  _buildAnimeVisuals(),
                  const SizedBox(height: 16),
                ],

                ...List.generate(_spots.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildSpotCard(index),
                  );
                }),

                const SizedBox(height: 8),

                // ── 行き先を追加ボタン ────────────────
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 130,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.grey.shade500, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '行き先を追加',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── BOTTOM BUTTON ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: const Color(0xFF10357A),
              child: TextButton(
                onPressed: _create,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                ),
                child: const Text(
                  'この内容で旅のしおりを作成する',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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

  List<Spot> get _animeVisualSpots {
    final unique = <String, Spot>{};
    for (final spot in _spots) {
      final animeId = spot.animeId;
      final key = animeId != null && animeId.isNotEmpty
          ? animeId
          : spot.animeTitle ?? '';
      if (key.isNotEmpty) unique.putIfAbsent(key, () => spot);
    }
    return unique.values.toList();
  }

  Widget _buildAnimeVisuals() => SizedBox(
    height: 140,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _animeVisualSpots.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (_, index) {
        final spot = _animeVisualSpots[index];
        return SizedBox(
          width: 240,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (spot.keyVisualUrl != null && spot.keyVisualUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: spot.keyVisualUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _placeholderImage(),
                  )
                else
                  _placeholderImage(),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xB34A76E8), Color(0x33745FC6)],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Text(
                    spot.animeTitle ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  // ── 聖地カード ────────────────────────────────────
  Widget _buildSpotCard(int index) {
    final spot = _spots[index];

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

          // ── テキスト情報 ──────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (spot.animeTitle?.isNotEmpty ?? false)
                    Text(
                      spot.animeTitle!,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _deleteSpot(index),
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 14,
                          color: Colors.red,
                        ),
                        label: const Text(
                          '削除',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          minimumSize: const Size(0, 28),
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
                            vertical: 7,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('詳細', style: TextStyle(fontSize: 12)),
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
