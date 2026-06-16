import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class AniTrailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final List<Widget>? actions;

  const AniTrailAppBar({super.key, this.showBack = false, this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: const Text(
        'AniTrail',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
