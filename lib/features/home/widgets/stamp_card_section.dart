import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/app_data_repository.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_shadows.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../map/models/anime_spot.dart';
import '../../search/screens/search_screen.dart';
import '../../shiori/screens/shiori_detail.dart';

enum _Filter { all, incomplete, complete }

class StampCardSection extends StatefulWidget {
  const StampCardSection({super.key});

  @override
  State<StampCardSection> createState() => _StampCardSectionState();
}

class _StampCardSectionState extends State<StampCardSection> {
  List<StampCard> _cards = [];
  bool _loading = true;
  Object? _error;
  AppDataRepository? _repository;
  _Filter _filter = _Filter.all;
  int? _expandedIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = context.read<AppDataRepository>();
    if (identical(repository, _repository)) return;
    _repository?.removeListener(_syncRepository);
    _repository = repository..addListener(_syncRepository);
    _cards = repository.stampCards;
    _loading = repository.loading;
    _error = repository.error;
  }

  Future<void> _load() async {
    await _repository?.load(refresh: true);
  }

  void _syncRepository() {
    final repository = _repository;
    if (!mounted || repository == null) return;
    setState(() {
      _cards = repository.stampCards;
      _loading = repository.loading;
      _error = repository.error;
    });
  }

  @override
  void dispose() {
    _repository?.removeListener(_syncRepository);
    super.dispose();
  }

  List<StampCard> get _filtered => switch (_filter) {
    _Filter.complete => _cards.where((c) => c.complete == true).toList(),
    _Filter.incomplete => _cards.where((c) => c.complete != true).toList(),
    _Filter.all => _cards,
  };

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
        const SizedBox(height: AppSpacing.xl),

        // ヘッダー行: [フィルター] 作成した旅のしおり [+作成]
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '作成した旅のしおり',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: AppTextStyles.subtitle,
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
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
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

        const SizedBox(height: AppSpacing.md),

        if (_loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: _buildLoadingAnimation(),
          )
        else if (_error != null && _cards.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('しおりを読み込めませんでした'),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: '再読み込み',
                    onPressed: _load,
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.compact,
                    fullWidth: false,
                  ),
                ],
              ),
            ),
          )
        else if (_cards.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xxxl),
            child: Center(
              child: Text(
                'まだ旅のしおりがありません',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          )
        else if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Center(
              child: Text(
                'この条件のしおりはありません',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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

        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildLoadingAnimation() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/loading.gif',
          width: 110,
          height: 110,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 4),
        const Text(
          'しおりを読み込んでいます・・・',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

// ── スタック表示 ─────────────────────────────────────────────────────────
class _StackedCards extends StatelessWidget {
  final List<StampCard> cards;
  final Map<String, String> authHeaders;
  final int? expandedIndex;
  final void Function(int) onExpand;
  final void Function(StampCard) onViewDetail;

  // カード本体の高さ
  static const double _cardH = 140.0;
  // 下のカードが覗く量
  static const double _peekH = 91.0;
  // 展開時に追加される高さ。
  // 前面カードに隠れず展開行を完全に見せるには
  // cardH(140) + 展開行(66) - peekH(91) = 115 以上が必要。
  static const double _expandH = 116.0;

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
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brLg,
          boxShadow: AppShadows.card,
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
    final bannerUrl = card.keyVisualUrls.firstOrNull;

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(AppRadius.lg),
        topRight: const Radius.circular(AppRadius.lg),
        bottomLeft: Radius.circular(isExpanded ? 0 : AppRadius.lg),
        bottomRight: Radius.circular(isExpanded ? 0 : AppRadius.lg),
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
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    errorWidget: (ctx, err, st) =>
                        Container(color: AppColors.primary),
                  )
                : Container(color: AppColors.primary),

            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.cardGradient),
            ),

            // 展開矢印
            Positioned(
              top: AppSpacing.md,
              right: 18,
              child: AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 260),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.white,
                  size: 32,
                ),
              ),
            ),

            // タイトル・聖地数
            Positioned(
              left: AppSpacing.lg,
              right: 54,
              top: 26,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
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
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: AppSpacing.xs),
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
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: previews.length,
                separatorBuilder: (ctx, i) =>
                    const SizedBox(width: AppSpacing.xs),
                itemBuilder: (ctx, i) => ClipRRect(
                  borderRadius: AppRadius.brSm,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: CachedNetworkImage(
                      imageUrl: previews[i],
                      httpHeaders: authHeaders,
                      fit: BoxFit.cover,
                      errorWidget: (ctx, err, st) =>
                          Container(color: AppColors.placeholder),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            label: '詳細を見る',
            onPressed: onViewDetail,
            size: AppButtonSize.compact,
            fullWidth: false,
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
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),

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
                const SizedBox(width: AppSpacing.xs),
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.brSm,
          border: Border.all(color: Colors.black),
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
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}
