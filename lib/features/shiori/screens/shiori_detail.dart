import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/styles/app_styles.dart';
import '../../../core/widgets/main_buttom_nav.dart';
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_outlined, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Text(
              'しおりタイトルを編集',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: TextFormField(
          initialValue: card.title,
          autofocus: true,
          maxLength: 60,
          decoration: InputDecoration(
            labelText: 'しおりタイトル',
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
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
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: AppColors.error, size: 22),
            SizedBox(width: 10),
            Text(
              'しおりを削除',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('しおりを読み込めませんでした'),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('再読み込み')),
            ],
          ),
        ),
      );
    }
    if (card == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
        ),
        body: Center(child: _buildLoadingAnimation(size: 160)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(card)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(child: _buildStampCard(card)),
          ),
          SliverToBoxAdapter(child: _buildListHeader()),
          if (_refreshing && _spots.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 32),
                child: _buildLoadingAnimation(size: 110),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: _spots.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
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
      const SizedBox(height: 4),
      const Text(
        'しおりを読み込んでいます・・・',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
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
                  left: 12,
                  child: _HeaderCircleButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  child: PopupMenuButton<String>(
                    enabled: !_mutating,
                    color: Colors.white,
                    elevation: 4,
                    offset: const Offset(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.more_vert,
                              color: Colors.white,
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
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _dateLabel(card.createdAt),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                          Text(
                            '聖地 ${card.spotCount}箇所',
                            style: const TextStyle(
                              color: Colors.white,
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
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'スタンプカード',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${_visitedSpotIds.length}/${card.spotCount}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                            ? Colors.white
                            : const Color(0xFFB3B3B3),
                        border: obtained
                            ? Border.all(color: AppColors.primary, width: 1.5)
                            : null,
                        borderRadius: BorderRadius.circular(8),
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
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<bool>(
              value: _nameOrder,
              isDense: true,
              borderRadius: BorderRadius.circular(10),
              items: const [
                DropdownMenuItem(value: false, child: Text('追加順')),
                DropdownMenuItem(value: true, child: Text('名前順')),
              ],
              onChanged: (value) => setState(() => _nameOrder = value ?? false),
            ),
          ),
        ),
        const Text(
          '行き先一覧',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
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
      height: 122,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
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
                      ? const ColoredBox(color: Color(0xFFE5E5E5))
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          httpHeaders: _authHeaders,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) =>
                              const ColoredBox(color: Color(0xFFE5E5E5)),
                        ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Colors.white,
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
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
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
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        visited ? '訪問済み' : '未訪問',
                        style: TextStyle(
                          fontSize: 11,
                          color: visited ? Colors.grey : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    spot.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    spot.addressText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () => _openSpot(spot),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: const Text(
                          '詳細',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
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
