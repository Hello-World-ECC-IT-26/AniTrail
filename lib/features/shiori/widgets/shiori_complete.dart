import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/widgets/main_buttom_nav.dart';
import '../../../core/widgets/app_bar.dart';
import '../../home/screens/home_screen.dart';
import '../../map/models/anime_spot.dart';
import '../../map/services/spot_api.dart';

class ShioriCompleteScreen extends StatefulWidget {
  /// 作成したしおりのID（stamp_cards.card_id）
  final String cardId;

  /// 作成したしおりのタイトル
  final String shioriTitle;

  /// しおりに追加した聖地リスト
  final List<Spot> spots;

  const ShioriCompleteScreen({
    super.key,
    required this.cardId,
    this.shioriTitle = 'しおりタイトル',
    this.spots = const [],
  });

  @override
  State<ShioriCompleteScreen> createState() => _ShioriCompleteScreenState();
}

class _ShioriCompleteScreenState extends State<ShioriCompleteScreen> {
  final SpotApi _api = SpotApi();
  Set<String> _visited = {};

  Map<String, String> get _authHeaders {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return token != null ? {'Authorization': 'Bearer $token'} : {};
  }

  @override
  void initState() {
    super.initState();
    _loadStamps();
  }

  Future<void> _loadStamps() async {
    final visited = await _api.fetchVisitedSpotIds(widget.cardId);
    if (mounted) setState(() => _visited = visited);
  }

  @override
  Widget build(BuildContext context) {
    final spots = widget.spots;
    final total = spots.length;
    final obtained = spots.where((s) => _visited.contains(s.spotId)).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AniTrailAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                '旅のしおりが作成されました！',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_animeVisualSpots.isNotEmpty) ...[
              _buildAnimeVisuals(),
              const SizedBox(height: 20),
            ],

            // ── しおりカード ──────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── ヘッダー（タイトル + 編集・削除） ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.shioriTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 編集ボタン（スコープ外・準備中）
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('編集は準備中です')),
                          );
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: Colors.black54,
                        ),
                        label: const Text(
                          '編集',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── 聖地リスト ──────────────────────
                  ...spots.map((spot) => _buildSpotRow(spot)),

                  const SizedBox(height: 20),

                  // ── スタンプカード ──────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'スタンプカード',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '$obtained/$total',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // スタンプグリッド（聖地数ぶん。取得済みを着色）
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 1,
                        ),
                    itemCount: total == 0 ? 10 : total,
                    itemBuilder: (_, i) {
                      final filled = i < obtained;
                      return Container(
                        decoration: BoxDecoration(
                          color: filled
                              ? AppColors.primary
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: filled
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Center(
              child: Text(
                '聖地を巡ってスタンプをゲットしましょう！',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── マップで確認ボタン（スコープ外・準備中） ──
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('マップ確認は準備中です')));
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  'マップで確認',
                  style: TextStyle(fontSize: 15, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
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
    for (final spot in widget.spots) {
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

  // ── 聖地の1行表示 ────────────────────────────────
  Widget _buildSpotRow(Spot spot) {
    final visited = _visited.contains(spot.spotId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              child: SizedBox(
                width: 120,
                height: 100,
                child: _buildThumbnail(spot),
              ),
            ),

            // ── テキスト情報 ──────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (spot.animeTitle?.isNotEmpty ?? false) ...[
                      Text(
                        spot.animeTitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 3),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            spot.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          visited ? '訪問済み' : '未訪問',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: visited ? Colors.grey : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      spot.addressText,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
