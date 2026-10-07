import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/styles/app_dimens.dart';
import '../models/anime_spot.dart';

/// 聖地一覧の1行
class SpotListItem extends StatelessWidget {
  final Spot spot;
  final String animeTitle;
  final VoidCallback? onTap;
  final String? routeDescription;
  final Size thumbnailSize;
  final EdgeInsetsGeometry padding;
  final Widget? trailing;
  final Map<String, String>? imageHeaders;
  final bool showDistance;

  const SpotListItem({
    super.key,
    required this.spot,
    required this.animeTitle,
    this.onTap,
    this.routeDescription,
    this.thumbnailSize = const Size(90, 72),
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    this.trailing,
    this.imageHeaders,
    this.showDistance = true,
  });

  String? _streetViewImageUrl() =>
      spot.streetViewProxyUrl ?? spot.streetViewImageUrl;

  Map<String, String> get _authHeaders {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return token != null ? {'Authorization': 'Bearer $token'} : {};
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: AppRadius.brSm,
              child: SizedBox(
                width: thumbnailSize.width,
                height: thumbnailSize.height,
                child: _buildThumbnail(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          !showDistance || spot.distanceText.isEmpty
                              ? spot.name
                              : '${spot.name} (${spot.distanceText})',
                          style: AppTextStyles.input.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (spot.visited) ...[
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                  if (spot.addressText.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      spot.addressText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: routeDescription == null
                          ? AppTextStyles.label
                          : AppTextStyles.caption.copyWith(fontSize: 9),
                    ),
                  ],
                  if (routeDescription != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      routeDescription!,
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    // 1. 聖地の実写真
    if (spot.image != null) {
      return CachedNetworkImage(
        imageUrl: spot.image!,
        httpHeaders: imageHeaders ?? _authHeaders,
        fit: BoxFit.cover,
        placeholder: (_, _) => _placeholder(),
        errorWidget: (_, _, _) => _streetViewOrPlaceholder(),
      );
    }
    // 2. Street View（実写真がない場合）
    return _streetViewOrPlaceholder();
  }

  Widget _streetViewOrPlaceholder() {
    final url = _streetViewImageUrl();
    if (url != null) {
      return CachedNetworkImage(
        imageUrl: url,
        httpHeaders: imageHeaders ?? _authHeaders,
        fit: BoxFit.cover,
        placeholder: (_, _) => _placeholder(),
        errorWidget: (_, _, _) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.placeholder,
      child: const Icon(Icons.image, color: AppColors.textHint),
    );
  }
}
