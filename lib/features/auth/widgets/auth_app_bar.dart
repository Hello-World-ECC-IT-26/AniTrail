import 'package:flutter/material.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';

/// 認証系画面で共通利用する、戻る矢印＋中央タイトルのアプリバー。
class AuthAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final double toolbarHeight;

  const AuthAppBar({
    super.key,
    required this.title,
    this.toolbarHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: toolbarHeight,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios,
            color: AppColors.textPrimary, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);
}
