import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class MainBottomNav extends StatelessWidget {
  final int? currentIndex;
  final ValueChanged<int> onTap;

  const MainBottomNav({super.key, this.currentIndex, required this.onTap});

  Widget _icon(String path, bool active) {
    return Image.asset(
      path,
      width: 24,
      height: 24,
      color: active ? AppColors.primary : Colors.grey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = currentIndex != null;

    return BottomNavigationBar(
      currentIndex: currentIndex ?? 0,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: hasSelection ? AppColors.primary : Colors.grey,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 8,
      items: [
        BottomNavigationBarItem(
          icon: _icon('assets/images/home.png', currentIndex == 0),
          label: 'ホーム',
        ),
        BottomNavigationBarItem(
          icon: _icon('assets/images/map.png', currentIndex == 1),
          label: 'マップ',
        ),
        BottomNavigationBarItem(
          icon: _icon('assets/images/stamp.png', currentIndex == 2),
          label: 'スタンプ',
        ),
        BottomNavigationBarItem(
          icon: _icon('assets/images/coupon.png', currentIndex == 3),
          label: 'クーポン',
        ),
      ],
    );
  }
}
