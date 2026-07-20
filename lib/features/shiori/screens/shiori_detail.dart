import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_shadows.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/main_buttom_nav.dart';
import '../../../core/widgets/loading_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../map/models/anime_spot.dart';
import '../../map/services/spot_api.dart';
import '../../spot/screens/spot_detail.dart';

class ShioriDetailScreen extends StatefulWidget {
  const ShioriDetailScreen({super.key, required this.cardId, this.initialCard});

  final String cardId;
  final StampCard? initialCard;

  @override
  State<ShioriDetailScreen> createState() => _ShioriDetailScreenState();
}

class _ShioriDetailScreenState extends State<ShioriDetailScreen> {
  final SpotApi _api = SpotApi();
  StampCard? _card;
  Set<String> _visitedSpotIds = {};
  Object? _error;
  bool _nameOrder = false;
  bool _refreshing = true;
  bool _mutating = false;

  Map<String, String> get _authHeaders {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return token == null ? {} : {'Authorization': 'Bearer $token'};
  }

  @override
  void initState() {
    super.initState();
    _card = widget.initialCard;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _refreshing = true;
    });
    try {
      final cached = await _api.readCachedStampCard(widget.cardId);
      if (cached != null && mounted) setState(() => _card = cached);

      final results = await Future.wait([
        _api.fetchStampCard(widget.cardId),
        _api.fetchVisitedSpotIds(widget.cardId),
      ]);
      if (!mounted) return;
      setState(() {
        _card = results[0] as StampCard;
        _visitedSpotIds = results[1] as Set<String>;
        _refreshing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _refreshing = false;
        if (_card == null) _error = error;
      });
    }
  }

  List<Spot> get _spots {
    final spots = List<Spot>.from(_card?.spots ?? const []);
    if (_nameOrder) spots.sort((a, b) => a.name.compareTo(b.name));
    return spots;
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    return '${local.month}月${local.day}日';
  }

  void _openSpot(Spot spot) {
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

  Future<void> _editTitle() async {
    final card = _card;
    if (card == null || _mutating) return;
    var draftTitle = card.title;
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        title: Row(
          children: [
            const Icon(Icons.edit_outlined, color: AppColors.primary, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Text('しおりタイトルを編集', style: AppTextStyles.heading),
          ],
        ),
        content: TextFormField(
          initialValue: card.title,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(
            labelText: 'しおりタイトル',
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          onChanged: (value) => draftTitle = value,
          onFieldSubmitted: (value) {
            final trimmed = value.trim();
            if (trimmed.isNotEmpty) Navigator.pop(dialogContext, trimmed);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final trimmed = draftTitle.trim();
              if (trimmed.isNotEmpty) Navigator.pop(dialogContext, trimmed);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (title == null || title == card.title || !mounted) return;

    setState(() => _mutating = true);
    try {
      await _api.updateStampCardTitle(widget.cardId, title);
      if (!mounted) return;
      setState(() {
        _card = card.copyWith(title: title);
        _mutating = false;
      });
      _showMessage('しおりを更新しました');
    } catch (error) {
      if (!mounted) return;
      setState(() => _mutating = false);
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deleteCard() async {
    if (_mutating) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: AppColors.error, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Text('しおりを削除', style: AppTextStyles.heading),
          ],
        ),
        content: const Text(
          'このしおりを削除しますか？\nこの操作は取り消せません。',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _mutating = true);
    try {
      await _api.deleteStampCard(widget.cardId);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _mutating = false);
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.background),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('しおりを読み込めませんでした'),
              const SizedBox(height: AppSpacing.md),
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
      );
    }
    if (card == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
        ),
        body: const AppLoadingScreen(message: 'しおりを読み込んでいます・・・'),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(card)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            sliver: SliverToBoxAdapter(child: _buildStampCard(card)),
          ),
          SliverToBoxAdapter(child: _buildListHeader()),
          if (_refreshing && _spots.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.xxxl,
                ),
                child: _buildLoadingAnimation(size: 110),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              sliver: SliverList.separated(
                itemCount: _spots.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, index) => _buildSpotCard(_spots[index]),
              ),
            ),
        ],
      ),
      bottomNavigationBar: MainBottomNav(
        currentIndex: 1,
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

  Widget _buildLoadingAnimation({required double size}) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset(
        'assets/images/loading.gif',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'しおりを読み込んでいます・・・',
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
      ),
    ],
  );

  Widget _buildHeader(StampCard card) {
    final visualUrl = card.keyVisualUrls.firstOrNull;
    return SizedBox(
      height: 176,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (visualUrl != null)
            CachedNetworkImage(
              imageUrl: visualUrl,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) =>
                  const ColoredBox(color: AppColors.primary),
            )
          else
            const ColoredBox(color: AppColors.primary),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33000000), Color(0x99000000)],
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: AppSpacing.md,
                  child: _HeaderCircleButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                ),
                Positioned(
                  right: AppSpacing.md,
                  child: PopupMenuButton<String>(
                    enabled: !_mutating,
                    color: AppColors.surface,
                    elevation: 4,
                    offset: const Offset(0, 44),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.brMd,
                    ),
                    onSelected: (value) {
                      if (value == 'edit') _editTitle();
                      if (value == 'delete') _deleteCard();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        height: 44,
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 10),
                            Text('タイトルを編集'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        height: 44,
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'しおりを削除',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: _HeaderCircleButton(
                      child: _mutating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Icon(
                              Icons.more_vert,
                              color: AppColors.white,
                              size: 24,
                            ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 56),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        card.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _dateLabel(card.createdAt),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.white,
                          ),
                          Text(
                            '聖地 ${card.spotCount}箇所',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }

  Widget _buildStampCard(StampCard card) {
    // しおりの聖地数ぶんだけマスを表示（最低1マス）
    final stampTotal = card.spotCount < 1 ? 1 : card.spotCount;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brLg,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'スタンプカード',
                style: AppTextStyles.subtitle.copyWith(fontSize: 17),
              ),
              const Spacer(),
              Text(
                '${_visitedSpotIds.length}/${card.spotCount}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              // 5列基準でマスのサイズを算出。最終行が埋まらなくても中央揃え。
              const spacing = 8.0;
              const columns = 5;
              final cellSize =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(stampTotal, (index) {
                  final obtained =
                      index < card.spots.length &&
                      _visitedSpotIds.contains(card.spots[index].spotId);
                  return SizedBox(
                    width: cellSize,
                    height: cellSize,
                    child: Container(
                      decoration: BoxDecoration(
                        color: obtained
                            ? AppColors.surface
                            : AppColors.textHint,
                        border: obtained
                            ? Border.all(color: AppColors.primary, width: 1.5)
                            : null,
                        borderRadius: AppRadius.brSm,
                      ),
                      child: obtained
                          ? const Icon(
                              Icons.verified,
                              color: AppColors.primary,
                              size: 36,
                            )
                          : null,
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.lg,
      AppSpacing.xl,
      AppSpacing.sm,
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<bool>(
              value: _nameOrder,
              isDense: true,
              borderRadius: AppRadius.brMd,
              items: const [
                DropdownMenuItem(value: false, child: Text('追加順')),
                DropdownMenuItem(value: true, child: Text('名前順')),
              ],
              onChanged: (value) => setState(() => _nameOrder = value ?? false),
            ),
          ),
        ),
        Text('行き先一覧', style: AppTextStyles.subtitle.copyWith(fontSize: 17)),
        Align(
          alignment: Alignment.centerRight,
          child: Visibility(
            visible: _refreshing && _spots.isNotEmpty,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Image.asset(
              'assets/images/loading.gif',
              width: 38,
              height: 38,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildSpotCard(Spot spot) {
    final visited = _visitedSpotIds.contains(spot.spotId);
    final imageUrl = spot.streetViewProxyUrl;
    return Container(
      // コンパクトボタンと3行のテキストを、端末ごとの文字描画差も
      // 含めて収めるため、内容領域に余裕を持たせる。
      height: 124,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brLg,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            height: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: imageUrl == null
                      ? const ColoredBox(color: AppColors.borderLight)
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          httpHeaders: _authHeaders,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) =>
                              const ColoredBox(color: AppColors.borderLight),
                        ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bookmark_outline,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          spot.animeTitle ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        visited ? '訪問済み' : '未訪問',
                        style: TextStyle(
                          fontSize: 11,
                          color: visited
                              ? AppColors.textMuted
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    spot.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.subtitle.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    spot.addressText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      label: '詳細',
                      onPressed: () => _openSpot(spot),
                      size: AppButtonSize.compact,
                      fullWidth: false,
                    ),
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

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({required this.child, this.onPressed});

  final Widget child;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      width: 40,
      height: 40,
      child: Center(child: child),
    );
    return Material(
      color: Colors.black.withValues(alpha: 0.28),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: onPressed == null
          ? content
          : InkWell(onTap: onPressed, child: content),
    );
  }
}
