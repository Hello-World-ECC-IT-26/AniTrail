import 'package:flutter/material.dart';

import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../map/models/anime_spot.dart';
import '../widgets/spot_comments_section.dart';

/// コレクション詳細から開く、聖地ごとのコメント画面。
class SpotCommentsScreen extends StatelessWidget {
  final Spot spot;
  final String animeTitle;

  const SpotCommentsScreen({
    super.key,
    required this.spot,
    required this.animeTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        title: const Text('コメント'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(spot.name, style: AppTextStyles.heading),
          const SizedBox(height: AppSpacing.xs),
          Text('アニメ「$animeTitle」', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xl),
          SpotCommentsSection(spotId: spot.spotId),
        ],
      ),
    );
  }
}
