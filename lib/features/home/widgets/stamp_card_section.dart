import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/styles/app_styles.dart';
import '../../map/models/anime_spot.dart';
import '../../map/services/spot_api.dart';
import '../../search/screens/search_screen.dart';
import '../../shiori/screens/shiori_detail.dart';

enum _Filter { all, incomplete, complete }

class StampCardSection extends StatefulWidget {
  const StampCardSection({super.key});

  @override
  State<StampCardSection> createState() => _StampCardSectionState();
}

class _StampCardSectionState extends State<StampCardSection> {
  final SpotApi _api = SpotApi();

  List<StampCard> _cards = [];
  bool _loading = true;
  _Filter _filter = _Filter.all;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cards = await _api.fetchStampCards();
      if (mounted) {
        setState(() {
          _cards = cards;
          _loading = false;
        });
        unawaited(_hydrateCards(cards.take(4).toList()));
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<StampCard> get _filtered => switch (_filter) {
    _Filter.complete => _cards.where((c) => c.complete == true).toList(),
    _Filter.incomplete => _cards.where((c) => c.complete != true).toList(),
    _Filter.all => _cards,
  };

  Future<void> _hydrateCards(List<StampCard> cards) async {
    final cached = await Future.wait(
      cards.map((card) => _api.readCachedStampCard(card.cardId)),
    );
    for (final card in cached.whereType<StampCard>()) {
      _replaceCard(card);
    }

    final details = await Future.wait(
      cards.map((card) async {
        try {
          return await _api.fetchStampCard(card.cardId);
        } catch (_) {
          return null;
        }
      }),
    );
    for (final card in details.whereType<StampCard>()) {
      _replaceCard(card);
    }
  }

  void _replaceCard(StampCard card) {
    if (!mounted) return;
    final index = _cards.indexWhere((item) => item.cardId == card.cardId);
    if (index < 0) return;
    setState(() => _cards[index] = card);
  }

  Map<String, String> get _authHeaders {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return token != null ? {'Authorization': 'Bearer $token'} : {};
  }

  void _onFilterChanged(_Filter filter) {
    setState(() {
      _filter = filter;
      _expandedIndex = null;
    });
  }

  String _filterLabel(_Filter filter) => switch (filter) {
    _Filter.all => '全て',
    _Filter.incomplete => '未完了',
    _Filter.complete => 'コンプリート',
  };

  Future<void> _onCreate() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // ヘッダー行: [フィルター] 作成した旅のしおり [+作成]
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // 左: フィルタードロップダウン（固定幅で中央タイトルを揃える）
              SizedBox(
                width: 96,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _cards.isEmpty
                      ? const SizedBox.shrink()
                      : _FilterDropdown(
                          current: _filter,
                          label: _filterLabel(_filter),
                          onChanged: _onFilterChanged,
                        ),
                ),
              ),

              // 中央: タイトル
              const Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '作成した旅のしおり',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

              // 右: +作成
              SizedBox(
                width: 96,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _onCreate,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      '作成',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

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
        else if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'この条件のしおりはありません',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _StackedCards(
              cards: filtered,
              authHeaders: _authHeaders,
              expandedIndex: _expandedIndex,
              onExpand: (i) => setState(
                () => _expandedIndex = _expandedIndex == i ? null : i,
              ),
              onViewDetail: (card) async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShioriDetailScreen(
                      cardId: card.cardId,
                      initialCard: card,
                    ),
                  ),
                );
                if (mounted) await _load();
              },
            ),
          ),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ── スタック表示 ─────────────────────────────────────────────────────────
class _StackedCards extends StatelessWidget {
  final List<StampCard> cards;
  final Map<String, String> authHeaders;
  final int? expandedIndex;
  final void Function(int) onExpand;
  final void Function(StampCard) onViewDetail;

  // カード本体の高さ
  static const double _cardH = 132.0;
  // 下のカードが覗く量
  static const double _peekH = 91.0;
  // 展開時に追加される高さ。
  // 前面カードに隠れず展開行を完全に見せるには
  // cardH(132) + 展開行(66) - peekH(91) = 107 以上が必要。
  static const double _expandH = 108.0;

  const _StackedCards({
    required this.cards,
    required this.authHeaders,
    required this.expandedIndex,
    required this.onExpand,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    final n = cards.length;
    double totalHeight =
        _cardH + (n - 1) * _peekH + (expandedIndex != null ? _expandH : 0);

    return SizedBox(
      height: totalHeight,
      child: Stack(
        children: List.generate(n, (i) {
          double top = i * _peekH;
          if (expandedIndex != null && i > expandedIndex!) top += _expandH;

          return Positioned(
            top: top,
            left: 0,
            right: 0,
            child: _ShioriCard(
              card: cards[i],
              authHeaders: authHeaders,
              isExpanded: expandedIndex == i,
              depth: n - 1 - i, // 0=最前面
              onTap: () => onExpand(i),
              onViewDetail: () => onViewDetail(cards[i]),
            ),
          );
        }),
      ),
    );
  }
}

// ── 個別カード ──────────────────────────────────────────────────────────
class _ShioriCard extends StatelessWidget {
  final StampCard card;
  final Map<String, String> authHeaders;
  final bool isExpanded;
  final int depth; // 0=最前面、1以上=背面
  final VoidCallback onTap;
  final VoidCallback onViewDetail;

  const _ShioriCard({
    required this.card,
    required this.authHeaders,
    required this.isExpanded,
    required this.depth,
    required this.onTap,
    required this.onViewDetail,
  });

  String? _dateLabel(DateTime? value) {
    if (value == null) return null;
    final local = value.toLocal();
    return '${local.month}月${local.day}日';
  }

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
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBanner(),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 260),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: _buildExpandedRow(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    // キービジュアル優先。無ければ一覧APIに含まれる聖地画像（Street View）にフォールバック。
    // → 詳細取得（hydrate）前でも青一色にならない。
    final bannerUrl =
        card.keyVisualUrls.firstOrNull ?? card.spotImageUrls.firstOrNull;
    // Street View プロキシ画像のみ Bearer 認証が必要。外部キービジュアルには付けない。
    final needsAuth = bannerUrl != null && bannerUrl.contains('/street-view/');

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(15),
        topRight: const Radius.circular(15),
        bottomLeft: Radius.circular(isExpanded ? 0 : 15),
        bottomRight: Radius.circular(isExpanded ? 0 : 15),
      ),
      child: SizedBox(
        width: double.infinity,
        height: _StackedCards._cardH,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 背景画像
            bannerUrl != null
                ? CachedNetworkImage(
                    imageUrl: bannerUrl,
                    httpHeaders: needsAuth ? authHeaders : null,
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    errorWidget: (ctx, err, st) =>
                        Container(color: AppColors.primary),
                  )
                : Container(color: AppColors.primary),

            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.28),
              ),
            ),

            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0x88000000), Colors.transparent],
                  stops: [0.0, 0.9],
                ),
              ),
            ),

            // 上→下グラデーション（下部ピーク部の可読性）
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x88000000)],
                  stops: [0.5, 1.0],
                ),
              ),
            ),

            // 展開矢印
            Positioned(
              top: 12,
              right: 18,
              child: AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 260),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),

            // タイトル・聖地数
            Positioned(
              left: 28,
              right: 54,
              top: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (_dateLabel(card.createdAt) != null) ...[
                        Text(
                          _dateLabel(card.createdAt)!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '聖地 ${card.spotCount}箇所',
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
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedRow() {
    final previews = card.spotImageUrls.take(4).toList();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: previews.length,
                separatorBuilder: (ctx, i) => const SizedBox(width: 6),
                itemBuilder: (ctx, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: CachedNetworkImage(
                      imageUrl: previews[i],
                      httpHeaders: authHeaders,
                      fit: BoxFit.cover,
                      errorWidget: (ctx, err, st) =>
                          Container(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: onViewDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

// ── フィルタードロップダウン ──────────────────────────────────────────────
class _FilterDropdown extends StatelessWidget {
  final _Filter current;
  final String label;
  final void Function(_Filter) onChanged;

  const _FilterDropdown({
    required this.current,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_Filter>(
      initialValue: current,
      onSelected: onChanged,
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) => [
        for (final f in _Filter.values)
          PopupMenuItem(
            value: f,
            height: 40,
            child: Row(
              children: [
                Icon(
                  f == current ? Icons.check : null,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(switch (f) {
                  _Filter.all => '全て',
                  _Filter.incomplete => '未完了',
                  _Filter.complete => 'コンプリート',
                }, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.textPrimary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
