import 'package:anitrail/features/coupon/screens/coupon_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/styles/app_dimens.dart';
import '../widgets/event_section.dart';
import '../widgets/user_section.dart';
import '../widgets/stamp_card_section.dart';
import '../../../core/widgets/main_buttom_nav.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../map/screens/map_screen.dart';
import '../../stamp/screens/all_stamp_collections_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../../core/data/app_data_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialIndex = 0})
    : assert(initialIndex >= 0 && initialIndex <= 3);

  final int initialIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  late final List<Widget?> _pages;

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
      await repository.load();
      if (mounted) await _prefetchHomeImages(repository);
    });
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
      1 => const MapScreen(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: _currentIndex != 0,
      backgroundColor: AppColors.background,
      appBar: _currentIndex == 1
          ? null
          : AniTrailAppBar(
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: AppColors.white),
                  onPressed: () => context.read<AuthProvider>().logout(),
                ),
              ],
            ),
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
              color: Colors.black.withOpacity(0.1),
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
