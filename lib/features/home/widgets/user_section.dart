import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/data/app_data_repository.dart';
import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../profile/screens/profile_screen.dart';

class UserInfoSection extends StatelessWidget {
  const UserInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<AppDataRepository>();
    final profile = repository.profile;
    final countLabel = repository.collectedStampCount?.toString() ?? '—';
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          _AvatarImage(url: profile?.avatarUrl),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: InkWell(
              onTap: () async {
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute(builder: (_) => const MyPageScreen()),
                );
                if (context.mounted) {
                  await context.read<AppDataRepository>().load(refresh: true);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.username ?? 'ユーザー',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('集めたスタンプ数：$countLabel', style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  final String? url;

  const _AvatarImage({this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.placeholder,
      ),
      child: ClipOval(
        child: url == null || url!.isEmpty
            ? const Icon(Icons.person)
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const Icon(Icons.person),
              ),
      ),
    );
  }
}
