import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../map/models/anime_spot.dart';
import '../../spot/screens/spot_comments_screen.dart';
import '../widgets/stamp_badge.dart';

class StampCollectionDetailDialog extends StatelessWidget {
  final Spot spot;
  final String animeTitle;
  final int stampIndex;
  final int stampTotal;
  final String? imageUrl;
  final List<String> arrivalPhotoUrls;
  final String? photoPath;
  final DateTime? obtainedAt;
  final int visitCount;

  const StampCollectionDetailDialog({
    super.key,
    required this.spot,
    required this.animeTitle,
    required this.stampIndex,
    required this.stampTotal,
    this.imageUrl,
    List<String>? arrivalPhotoUrls,
    this.photoPath,
    this.obtainedAt,
    required this.visitCount,
  }) : arrivalPhotoUrls = arrivalPhotoUrls ?? const [];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: math.min(760, screenHeight - AppSpacing.xxl),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 680;
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      tooltip: '閉じる',
                      icon: const Icon(Icons.close, size: 20),
                      color: AppColors.textSecondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Expanded(child: _mediaSection(compact: compact)),
                  SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
                  Text(
                    'アニメ「$animeTitle」',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.heading.copyWith(
                      color: const Color(0xFF12265A),
                      fontSize: compact ? 16 : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '訪問回数: $visitCount回　|　最終訪問: ${_dateText(obtainedAt)}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    height: compact ? 44 : AppSizes.buttonHeight,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) => SpotCommentsScreen(
                              spot: spot,
                              animeTitle: animeTitle,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('コメントする'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _mediaSection({required bool compact}) {
    if (compact) {
      return Row(
        children: [
          Expanded(child: _stampSection()),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _photoSection()),
        ],
      );
    }
    return Column(
      children: [
        Expanded(flex: 6, child: _stampSection()),
        const SizedBox(height: AppSpacing.sm),
        Expanded(flex: 5, child: _photoSection()),
      ],
    );
  }

  Widget _stampSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        return Center(
          child: StampBadge(label: spot.name, size: size),
        );
      },
    );
  }

  Widget _photoSection() {
    final userPhotos = [
      ...arrivalPhotoUrls.where((url) => url.isNotEmpty),
      if (photoPath != null && photoPath!.isNotEmpty) photoPath!,
    ];
    if (userPhotos.length > 1) {
      return ClipRRect(
        borderRadius: AppRadius.brSm,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: userPhotos.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            final photo = userPhotos[index];
            return AspectRatio(
              aspectRatio: 4 / 3,
              child: _ZoomablePhoto(
                photo: photo,
                borderRadius: AppRadius.brSm,
                child: _userPhoto(photo),
              ),
            );
          },
        ),
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: _ZoomablePhoto(
          photo: userPhotos.isNotEmpty ? userPhotos.first : imageUrl,
          borderRadius: AppRadius.brSm,
          child: userPhotos.isNotEmpty
              ? _userPhoto(userPhotos.first)
              : _photo(),
        ),
      ),
    );
  }

  Widget _userPhoto(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return _networkPhoto(value);
    }
    if (value.isNotEmpty) {
      return Image.file(
        File(value),
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      );
    }
    return const ColoredBox(color: AppColors.placeholder);
  }

  Widget _photo() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return _networkPhoto(imageUrl!);
    }
    return const ColoredBox(color: AppColors.placeholder);
  }

  Widget _networkPhoto(String url) => CachedNetworkImage(
    imageUrl: url,
    fit: BoxFit.cover,
    placeholder: (_, _) => const ColoredBox(color: AppColors.placeholder),
    errorWidget: (_, _, _) => const ColoredBox(color: AppColors.placeholder),
  );

  String _dateText(DateTime? date) {
    if (date == null) return '-';
    final value = date.toLocal();
    return '${value.year}年${value.month}月${value.day}日';
  }
}

class _ZoomablePhoto extends StatelessWidget {
  final String? photo;
  final BorderRadius borderRadius;
  final Widget child;

  const _ZoomablePhoto({
    required this.photo,
    required this.borderRadius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final value = photo;
    return ClipRRect(
      borderRadius: borderRadius,
      child: Material(
        color: AppColors.placeholder,
        child: InkWell(
          onTap: value == null || value.isEmpty
              ? null
              : () => _showExpandedPhoto(context, value),
          child: child,
        ),
      ),
    );
  }

  void _showExpandedPhoto(BuildContext context, String value) {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.86),
      builder: (context) => Dialog.fullscreen(
        backgroundColor: AppColors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: _ExpandedPhotoImage(value: value),
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: IconButton(
                  tooltip: '閉じる',
                  icon: const Icon(Icons.close, color: AppColors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandedPhotoImage extends StatelessWidget {
  final String value;

  const _ExpandedPhotoImage({required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: value,
        fit: BoxFit.contain,
        placeholder: (_, _) => const ColoredBox(color: AppColors.black),
        errorWidget: (_, _, _) => const ColoredBox(color: AppColors.black),
      );
    }
    return Image.file(
      File(value),
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}
