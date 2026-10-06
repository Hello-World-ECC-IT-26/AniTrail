import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../map/models/anime_spot.dart';

/// アニメ検索後の聖地一覧で使う、写真と追加操作を備えたカード。
class SpotListCard extends StatelessWidget {
  const SpotListCard({
    super.key,
    required this.spot,
    required this.animeTitle,
    required this.thumbnail,
    required this.selected,
    required this.onAdd,
    required this.onOpen,
  });

  final Spot spot;
  final String animeTitle;
  final Widget thumbnail;
  final bool selected;
  final VoidCallback onAdd;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final expandedText =
            constraints.maxWidth < 360 || scaler.scale(12) > 15;
        final imageWidth = math.min(
          160.0,
          constraints.maxWidth * (expandedText ? .34 : .39),
        );
        final textWidth = constraints.maxWidth - imageWidth - AppSpacing.md * 2;
        final lines = expandedText ? 2 : 1;
        const titleStyle = TextStyle(
          fontSize: 12,
          height: 1.2,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        );
        const nameStyle = TextStyle(
          fontSize: 16,
          height: 1.2,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        );
        const addressStyle = TextStyle(
          fontSize: 12,
          height: 1.2,
          color: AppColors.textMuted,
        );
        final title = spot.animeTitle ?? animeTitle;
        double textHeight(String text, TextStyle style) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: Directionality.of(context),
            textScaler: scaler,
            maxLines: lines,
          )..layout(maxWidth: textWidth);
          final height = painter.height;
          painter.dispose();
          return height;
        }

        final actionHeight = math.max(
          AppSizes.minTapTarget,
          scaler.scale(16) * 1.5 + 24,
        );
        final height = math.max(
          120.0,
          textHeight(title, titleStyle) +
              textHeight(spot.name, nameStyle) +
              textHeight(spot.addressText, addressStyle) +
              actionHeight +
              24,
        );
        return AppCard(
          clip: true,
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                SizedBox(width: imageWidth, height: height, child: thumbnail),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: titleStyle,
                          maxLines: lines,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          spot.name,
                          style: nameStyle,
                          maxLines: lines,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          spot.addressText,
                          style: addressStyle,
                          maxLines: lines,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: AppButton(
                            label: selected ? '追加済み' : '追加',
                            icon: selected ? Icons.check : Icons.add,
                            backgroundColor: AppColors.spotListAction,
                            fullWidth: false,
                            height: actionHeight,
                            onPressed: onAdd,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
