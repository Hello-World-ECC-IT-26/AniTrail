import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class AniTrailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;

  const AniTrailAppBar({super.key, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: const Text(
        'AniTrail',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
