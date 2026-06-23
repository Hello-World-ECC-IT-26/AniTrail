import 'package:flutter/material.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/styles/app_dimens.dart';

class UserInfoSection extends StatelessWidget {
  const UserInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          // アバター（未設定時はグレーの人アイコン）
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.placeholder,
            ),
            child: const Icon(Icons.person),
          ),
          const SizedBox(width: AppSpacing.md),

          // ユーザー名・スタンプ数
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('かなや',
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('集めたスタンプ数：10', style: AppTextStyles.caption),
              ],
            ),
          ),

          // 通知ボタン（TODO: 通知画面へ遷移）
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
