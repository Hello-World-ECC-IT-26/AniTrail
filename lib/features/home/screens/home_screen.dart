import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  const HomeScreen({super.key, this.initialIndex = 1})
    : assert(initialIndex >= 0 && initialIndex <= 2);

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
      const MapScreen(),
      _HomeBody(onSearchTap: _onSearchTap),
      const StampScreen(),
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
      backgroundColor: Colors.white,
      appBar: _currentIndex == 0
          ? null
          : AniTrailAppBar(
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
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

          const SizedBox(height: 24),
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
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Text('検索', style: TextStyle(color: Colors.grey.shade500)),
            const Spacer(),
            Icon(Icons.search, color: Colors.grey.shade500),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
