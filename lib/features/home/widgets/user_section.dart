import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../auth/services/auth_service.dart';
import '../../map/services/spot_api.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/services/profile_service.dart';

class UserInfoSection extends StatefulWidget {
  const UserInfoSection({super.key});

  @override
  State<UserInfoSection> createState() => _UserInfoSectionState();
}

class _UserInfoSectionState extends State<UserInfoSection> {
  late Future<UserProfile> _profileFuture;
  late Future<int> _stampCountFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
    _stampCountFuture = SpotApi().fetchCollectedStampCount();
  }

  Future<UserProfile> _loadProfile() async {
    await AuthService().ensureProfile();
    return ProfileService().fetchMyProfile();
  }

  void _reloadData() {
    setState(() {
      _profileFuture = _loadProfile();
      _stampCountFuture = SpotApi().fetchCollectedStampCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final profile = snapshot.data;
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
                    if (mounted) _reloadData();
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
                      FutureBuilder<int>(
                        future: _stampCountFuture,
                        builder: (context, countSnapshot) {
                          final countLabel = countSnapshot.hasData
                              ? countSnapshot.data.toString()
                              : '—';
                          return Text(
                            '集めたスタンプ数：$countLabel',
                            style: AppTextStyles.caption,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black,
                ),
                onPressed: () {},
              ),
            ],
          ),
        );
      },
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
