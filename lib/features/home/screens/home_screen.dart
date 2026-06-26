import 'package:AniTrail/features/coupon/screens/coupon_screen.dart';
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
import '../../stamp/screens/stamp_screen.dart';
import '../../search/screens/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialIndex = 0})
    : assert(initialIndex >= 0 && initialIndex <= 3);

  final int initialIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  // 各タブの画面リスト
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      _HomeBody(onSearchTap: _onSearchTap),
      const MapScreen(),
      const StampScreen(),
      const CouponListScreen(),
    ];
  }

  // ボトムナビゲーションタップ時の処理
  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  // 検索画面へ遷移し、戻り値でタブを切り替える
  Future<void> _onSearchTap() async {
    final index = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
    if (index != null) {
      setState(() => _currentIndex = index);
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
      body: IndexedStack(index: _currentIndex, children: _pages),
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
        decoration: const BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: AppRadius.brSm,
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
