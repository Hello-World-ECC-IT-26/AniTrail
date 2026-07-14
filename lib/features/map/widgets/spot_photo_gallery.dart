import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_styles.dart';

/// 聖地詳細で使う、画像数に応じて高さが伸びる写真ギャラリー。
///
/// `GridView` 自身はスクロールさせず、親の詳細画面のスクロールに任せることで
/// 複数画像でもレイアウトの制約エラーやオーバーフローを起こさない。
class SpotPhotoGallery extends StatelessWidget {
  final List<String> photoUrls;
  final Map<String, String> authHeaders;
  final bool Function(String url) requiresAuthHeaders;

  const SpotPhotoGallery({
    super.key,
    required this.photoUrls,
    required this.authHeaders,
    required this.requiresAuthHeaders,
  });

  @override
  Widget build(BuildContext context) {
    final photos = photoUrls.where((url) => url.trim().isNotEmpty).toList();
    if (photos.isEmpty) return const SizedBox.shrink();

    if (photos.length == 1) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: _PhotoTile(
          url: photos.first,
          httpHeaders: requiresAuthHeaders(photos.first)
              ? authHeaders
              : const {},
        ),
      );
    }

    return GridView.builder(
      primary: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 4 / 3,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final url = photos[index];
        return _PhotoTile(
          url: url,
          httpHeaders: requiresAuthHeaders(url) ? authHeaders : const {},
        );
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String url;
  final Map<String, String> httpHeaders;

  const _PhotoTile({required this.url, required this.httpHeaders});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.brSm,
      child: CachedNetworkImage(
        imageUrl: url,
        httpHeaders: httpHeaders,
        fit: BoxFit.cover,
        placeholder: (_, _) => const ColoredBox(color: AppColors.placeholder),
        errorWidget: (_, _, _) =>
            const ColoredBox(color: AppColors.placeholder),
      ),
    );
  }
}
