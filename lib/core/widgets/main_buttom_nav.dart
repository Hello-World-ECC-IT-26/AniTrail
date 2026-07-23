import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class MainBottomNav extends StatelessWidget {
  final int? currentIndex;
  final ValueChanged<int> onTap;

  const MainBottomNav({super.key, this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasSelection = currentIndex != null;
    final index = currentIndex ?? 0;

    return BottomNavigationBar(
      currentIndex: index,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: hasSelection ? AppColors.primary : Colors.grey,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 8,

      items: [
        BottomNavigationBarItem(
          icon: _icon('assets/images/home.png', hasSelection && index == 0),
          label: 'ホーム',
        ),
        BottomNavigationBarItem(
          icon: _icon('assets/images/map.png', hasSelection && index == 1),
          label: 'マップ',
        ),
        BottomNavigationBarItem(
          icon: _icon('assets/images/stamp.png', hasSelection && index == 2),
          label: 'スタンプ',
        ),
        BottomNavigationBarItem(
          icon: _icon('assets/images/coupon.png', hasSelection && index == 3),
          label: 'クーポン',
        ),
      ],
    );
  }

  Widget _icon(String path, bool isActive) {
    return Image.asset(
      path,
      width: 24,
      height: 24,
      color: isActive ? AppColors.primary : Colors.grey,
    );
  }
}
