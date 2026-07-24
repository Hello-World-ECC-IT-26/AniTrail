import 'package:anitrail/features/coupon/screens/coupon_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/app_data_repository.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/styles/app_dimens.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/main_buttom_nav.dart';
import '../../coupon/data/coupon_repository.dart';
import '../../coupon/models/coupon.dart';
import '../../coupon/widgets/coupon_detail.dart';
import '../../coupon/widgets/coupon_grant_dialog.dart';
import '../../map/models/anime_spot.dart';
import '../../map/screens/map_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../stamp/screens/all_stamp_collections_screen.dart';
import '../widgets/event_section.dart';
import '../widgets/home_tutorial.dart';
import '../widgets/stamp_card_section.dart';
import '../widgets/user_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialIndex = 0, this.initialMapShiori})
    : assert(initialIndex >= 0 && initialIndex <= 3);

  final int initialIndex;
  final StampCard? initialMapShiori;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  late final List<Widget?> _pages;
  bool _pendingCouponDialogShown = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = List<Widget?>.filled(4, null);
    _pages[0] = _HomeBody(onSearchTap: _onSearchTap);
    _ensurePage(_currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final repository = context.read<AppDataRepository>();
      final load = repository.load();
      await _showTutorial();
      await load;
      if (mounted) await _prefetchHomeImages(repository);
      if (mounted) {
        await _showPendingCouponGrants(repository.pendingCouponGrants);
      }
    });
  }

  Future<void> _showPendingCouponGrants(List<CouponGrant> grants) async {
    if (_pendingCouponDialogShown || grants.isEmpty) return;
    _pendingCouponDialogShown = true;
    final viewCoupons = await showCouponGrantDialog(context, grants);
    if (!mounted) return;
    final couponRepository = context.read<CouponRepository>();
    try {
      await Future.wait(
        grants.map((grant) => couponRepository.markGrantSeen(grant.grantId)),
      );
      if (!mounted) return;
      context.read<AppDataRepository>().removePendingCouponGrants(
        grants.map((grant) => grant.grantId),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('獲得通知の確認に失敗しました: $error')));
      }
    }
    if (!viewCoupons || !mounted) return;
    try {
      if (couponRepository.category != null) {
        await couponRepository.setCategory(null);
      } else {
        await couponRepository.load(refresh: true);
      }
      if (!mounted) return;
      if (grants.length == 1) {
        final couponId = grants.single.couponId;
        final coupon = couponRepository.coupons
            .where((item) => item.id == couponId)
            .firstOrNull;
        if (coupon != null) {
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => CouponDetailScreen(coupon: coupon),
            ),
          );
          return;
        }
      }
      setState(() {
        _ensurePage(3);
        _currentIndex = 3;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('クーポンを開けませんでした: $error')));
      }
    }
  }

  Future<void> _prefetchHomeImages(AppDataRepository repository) async {
    final urls = repository.stampCards
        .expand((card) => [...card.keyVisualUrls, ...card.spotImageUrls])
        .where((url) => url.isNotEmpty)
        .toSet()
        .take(4)
        .toList();
    var next = 0;
    Future<void> worker() async {
      while (next < urls.length && mounted) {
        final url = urls[next++];
        try {
          await precacheImage(CachedNetworkImageProvider(url), context);
        } catch (_) {
          // 先読みは表示時の通常エラー処理を変更しない。
        }
      }
    }

    await Future.wait([worker(), worker()]);
  }

  void _ensurePage(int index) {
    _pages[index] ??= switch (index) {
      0 => _HomeBody(onSearchTap: _onSearchTap),
      1 => MapScreen(initialShiori: widget.initialMapShiori),
      2 => const AllStampCollectionsScreen(showBackButton: false),
      _ => const CouponScreen(),
    };
  }

  // ボトムナビゲーションタップ時の処理
  void _onNavTap(int index) {
    setState(() {
      _ensurePage(index);
      _currentIndex = index;
    });
  }

  // 検索画面へ遷移し、戻り値でタブを切り替える
  Future<void> _onSearchTap() async {
    final index = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
    if (index != null) {
      setState(() {
        _ensurePage(index);
        _currentIndex = index;
      });
    }
  }

  Future<void> _showTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('tutorialShown') ?? false;
    if (shown || !mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const TutorialDialog(),
    );
    await prefs.setBool('tutorialShown', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: _currentIndex != 0,
      backgroundColor: AppColors.background,
      appBar: _currentIndex == 1 ? null : const AniTrailAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(
          _pages.length,
          (index) => _pages[index] ?? const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: MainBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

// ホーム画面のメインコンテンツ
class _HomeBody extends StatelessWidget {
  final VoidCallback onSearchTap;

  const _HomeBody({required this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ユーザー情報セクション
          const UserInfoSection(),

          // 検索バー（タップで検索画面へ遷移）*search_screen.dart*
          GestureDetector(
            onTap: onSearchTap,
            child: const AbsorbPointer(child: _SearchBar()),
          ),

          // イベントセクション *event_section.dart*
          const EventSection(),

          // スタンプカード一覧 *stamp_card_section*
          const StampCardSection(),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ── 検索バー（home専用、search_section.dartを統合） ────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.brSm,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          children: [
            SizedBox(width: AppSpacing.md),
            Text('検索', style: AppTextStyles.hint),
            Spacer(),
            Icon(Icons.search, color: AppColors.iconMuted),
            SizedBox(width: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
