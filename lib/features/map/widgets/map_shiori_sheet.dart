import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_shadows.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_chip.dart';
import '../../search/widgets/search_result_card.dart';
import '../../spot/screens/spot_detail.dart';
import '../models/anime_spot.dart';
import '../services/spot_api.dart';
import 'spot_list_item.dart';

const _kFilters = ['すべて', '訪問済み', '未訪問'];

/// マップ右上のしおりボタンで開くシート。
/// しおり一覧（アニメ画像カード）→ タップで聖地一覧（同じシート内）へドリルダウン。
/// 聖地一覧表示時はマップに聖地ピンを打つ。
class MapShioriSheet extends StatefulWidget {
  /// シートを閉じる
  final VoidCallback onClose;

  /// しおり選択時、その聖地一覧をマップにピン表示する
  final ValueChanged<List<Spot>> onShowSpots;

  /// 一覧に戻る等でピンをクリアする
  final VoidCallback onClearSpots;
  final ValueChanged<bool> onDetailVisibilityChanged;

  const MapShioriSheet({
    super.key,
    required this.onClose,
    required this.onShowSpots,
    required this.onClearSpots,
    required this.onDetailVisibilityChanged,
  });

  @override
  State<MapShioriSheet> createState() => _MapShioriSheetState();
}

class _MapShioriSheetState extends State<MapShioriSheet> {
  final SpotApi _api = SpotApi();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // しおり一覧
  List<StampCard> _cards = [];
  bool _loading = true;
  Object? _error;
  int _filterIndex = 0;

  // ドリルダウン中のしおり（null なら一覧表示）
  StampCard? _selected;
  bool _spotsLoading = false;

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
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

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

  List<StampCard> get _filtered => switch (_filterIndex) {
    1 => _cards.where((c) => c.complete == true).toList(),
    2 => _cards.where((c) => c.complete != true).toList(),
    _ => _cards,
  };

  Future<void> _openShiori(StampCard card) async {
    setState(() {
      _selected = card;
      _spotsLoading = card.spots.isEmpty;
    });
    widget.onDetailVisibilityChanged(true);
    // 聖地（lat/lng 付き）を取得してピン表示
    try {
      final full = card.spots.isNotEmpty
          ? card
          : await _api.fetchStampCard(card.cardId);
      if (!mounted || _selected?.cardId != card.cardId) return;
      setState(() {
        _selected = full;
        _spotsLoading = false;
      });
      widget.onShowSpots(full.spots);
    } catch (_) {
      if (mounted) setState(() => _spotsLoading = false);
    }
  }

  void _backToList() {
    setState(() => _selected = null);
    widget.onClearSpots();
    widget.onDetailVisibilityChanged(false);
  }

  void _dragSheetFromBanner(DragUpdateDetails details) {
    if (!_sheetController.isAttached) return;
    final height = MediaQuery.sizeOf(context).height;
    final delta = details.primaryDelta ?? 0;
    final next = (_sheetController.size - delta / height).clamp(0.3, 0.9);
    _sheetController.jumpTo(next);
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                boxShadow: AppShadows.sheet,
              ),
              child: Column(
                children: [
                  _buildHandle(),
                  _buildHeader(),
                  const Divider(height: 1),
                  Expanded(
                    child: _selected == null
                        ? _buildShioriList(scrollController)
                        : _buildSpotList(scrollController, _selected!),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.grey,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ── ヘッダー（一覧:フィルター / 詳細:戻る + タイトル） ──
  Widget _buildHeader() {
    final selected = _selected;
    if (selected == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
        child: Row(
          children: List.generate(_kFilters.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: AppChip(
                label: _kFilters[i],
                selected: _filterIndex == i,
                onTap: () => setState(() => _filterIndex = i),
              ),
            );
          }),
        ),
      );
    }
    // 詳細ヘッダー: 戻る + しおりタイトル
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs, 0, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
            onPressed: _backToList,
          ),
          Expanded(
            child: Text(
              selected.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.input.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Text('聖地 ${selected.spotCount}箇所', style: AppTextStyles.label),
        ],
      ),
    );
  }

  // ── レベル0: しおり一覧（検索カード風） ──
  Widget _buildShioriList(ScrollController controller) {
    if (_loading) {
      return _buildLoadingAnimation('しおりを読み込んでいます・・・');
    }
    if (_error != null) {
      return _centerMessage('しおりを読み込めませんでした', retry: true);
    }
    final cards = _filtered;
    if (cards.isEmpty) {
      return _centerMessage(
        _filterIndex == 0 ? 'まだ旅のしおりがありません' : '該当するしおりはありません',
      );
    }
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
      itemCount: cards.length,
      separatorBuilder: (context, i) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) {
        final card = cards[i];
        return SearchResultCard(
          title: card.title,
          bannerImage: card.keyVisualUrls.firstOrNull,
          spotCount: card.spotCount,
          spotImages: card.spotImageUrls,
          httpHeaders: _authHeaders,
          variableSpotImages: true,
          onBannerVerticalDragUpdate: _dragSheetFromBanner,
          onViewSpots: () => _openShiori(card),
        );
      },
    );
  }

  // ── レベル1: 聖地一覧 ──
  Widget _buildSpotList(ScrollController controller, StampCard card) {
    if (_spotsLoading) {
      return _buildLoadingAnimation('聖地を読み込んでいます・・・');
    }
    final spots = card.spots;
    if (spots.isEmpty) {
      return _centerMessage('聖地が登録されていません');
    }
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      itemCount: spots.length,
      separatorBuilder: (context, i) =>
          const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, i) {
        final spot = spots[i];
        return SpotListItem(
          spot: spot,
          animeTitle: spot.animeTitle ?? '',
          onTap: () => _openSpotDetail(spot),
        );
      },
    );
  }

  Future<void> _openSpotDetail(Spot spot) async {
    await Navigator.push(
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

  Widget _centerMessage(String text, {bool retry = false}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: const TextStyle(color: AppColors.textMuted)),
          if (retry) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: '再読み込み',
              onPressed: _load,
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.compact,
              fullWidth: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingAnimation(String message) {
    return Center(
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
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
