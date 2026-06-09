import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class MainBottomNav extends StatelessWidget {
  final int? currentIndex;
  final ValueChanged<int> onTap;

  const MainBottomNav({
    super.key,
    this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = currentIndex != null;
    return BottomNavigationBar(
      currentIndex: currentIndex ?? 0,
      onTap: onTap,
      selectedItemColor: hasSelection ? AppColors.primary : Colors.grey,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map),
          label: 'マップ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'ホーム',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.style_outlined),
          activeIcon: Icon(Icons.style),
          label: 'スタンプ',
        ),
      ],
    );
  }
}
