import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';

enum SpotPhotoKind { streetView, user }

class SpotPhoto {
  const SpotPhoto({
    required this.url,
    required this.kind,
    this.httpHeaders = const {},
  });

  final String url;
  final SpotPhotoKind kind;
  final Map<String, String> httpHeaders;

  bool get isStreetView => kind == SpotPhotoKind.streetView;
}

List<SpotPhoto> orderedSpotPhotos({
  String? streetViewUrl,
  Iterable<String> userPhotoUrls = const [],
  Map<String, String> streetViewHeaders = const {},
}) {
  final photos = <SpotPhoto>[];
  final seen = <String>{};
  final streetView = streetViewUrl?.trim();
  if (streetView != null && streetView.isNotEmpty) {
    seen.add(streetView);
    photos.add(
      SpotPhoto(
        url: streetView,
        kind: SpotPhotoKind.streetView,
        httpHeaders: streetViewHeaders,
      ),
    );
  }
  for (final value in userPhotoUrls) {
    final url = value.trim();
    if (url.isEmpty || !seen.add(url)) continue;
    photos.add(SpotPhoto(url: url, kind: SpotPhotoKind.user));
  }
  return photos;
}

class SpotPhotoGallery extends StatefulWidget {
  const SpotPhotoGallery({
    super.key,
    required this.streetViewUrl,
    required this.userPhotoUrls,
    this.streetViewHeaders = const {},
  });

  final String? streetViewUrl;
  final Iterable<String> userPhotoUrls;
  final Map<String, String> streetViewHeaders;

  @override
  State<SpotPhotoGallery> createState() => _SpotPhotoGalleryState();
}

class _SpotPhotoGalleryState extends State<SpotPhotoGallery> {
  int _selectedIndex = 0;

  List<SpotPhoto> get _photos => orderedSpotPhotos(
    streetViewUrl: widget.streetViewUrl,
    userPhotoUrls: widget.userPhotoUrls,
    streetViewHeaders: widget.streetViewHeaders,
  );

  @override
  void didUpdateWidget(covariant SpotPhotoGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex >= _photos.length) _selectedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photos;
    if (photos.isEmpty) return const _EmptyPhoto();
    final selected = photos[_selectedIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('写真', style: AppTextStyles.heading),
            const Spacer(),
            Text('${photos.length}枚', style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          key: const ValueKey('spot-photo-main'),
          onTap: () => _openViewer(context, photos, _selectedIndex),
          child: ClipRRect(
            borderRadius: AppRadius.brMd,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _PhotoImage(photo: selected),
                  if (selected.isStreetView)
                    const Positioned(
                      left: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: _StreetViewLabel(),
                    ),
                  const Positioned(
                    right: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xB3000000),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.fullscreen,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final photo = photos[index];
              final selected = index == _selectedIndex;
              return GestureDetector(
                key: ValueKey('spot-photo-thumbnail-$index'),
                onTap: () => setState(() => _selectedIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 94,
                  padding: EdgeInsets.all(selected ? 2 : 0),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.brSm,
                    border: selected
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _PhotoImage(photo: photo),
                        if (photo.isStreetView)
                          const Positioned(
                            left: 4,
                            bottom: 4,
                            child: Icon(
                              Icons.streetview,
                              color: AppColors.white,
                              size: 17,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openViewer(
    BuildContext context,
    List<SpotPhoto> photos,
    int initialIndex,
  ) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            _SpotPhotoViewer(photos: photos, initialIndex: initialIndex),
      ),
    );
  }
}

class _SpotPhotoViewer extends StatefulWidget {
  const _SpotPhotoViewer({required this.photos, required this.initialIndex});

  final List<SpotPhoto> photos;
  final int initialIndex;

  @override
  State<_SpotPhotoViewer> createState() => _SpotPhotoViewerState();
}

class _SpotPhotoViewerState extends State<_SpotPhotoViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  IconButton(
                    key: const ValueKey('spot-photo-viewer-close'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.white),
                  ),
                  const Spacer(),
                  Text(
                    '${_index + 1} / ${widget.photos.length}',
                    style: const TextStyle(color: AppColors.white),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                key: const ValueKey('spot-photo-viewer-pages'),
                controller: _controller,
                itemCount: widget.photos.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) {
                  final photo = widget.photos[index];
                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _PhotoImage(photo: photo, fit: BoxFit.contain),
                        if (photo.isStreetView)
                          const Positioned(
                            left: AppSpacing.md,
                            bottom: AppSpacing.md,
                            child: _StreetViewLabel(),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: 78,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: widget.photos.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => _controller.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                  ),
                  child: Container(
                    width: 82,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: index == _index
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: _PhotoImage(photo: widget.photos[index]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoImage extends StatefulWidget {
  const _PhotoImage({required this.photo, this.fit = BoxFit.cover});

  final SpotPhoto photo;
  final BoxFit fit;

  @override
  State<_PhotoImage> createState() => _PhotoImageState();
}

class _PhotoImageState extends State<_PhotoImage> {
  int _retry = 0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.photo.isStreetView ? 'Street View写真' : 'ユーザー投稿写真',
      image: true,
      child: CachedNetworkImage(
        key: ValueKey('${widget.photo.url}:$_retry'),
        imageUrl: widget.photo.url,
        httpHeaders: widget.photo.httpHeaders,
        fit: widget.fit,
        placeholder: (_, _) => const ColoredBox(color: AppColors.placeholder),
        errorWidget: (_, _, _) => ColoredBox(
          color: AppColors.placeholder,
          child: Center(
            child: TextButton.icon(
              onPressed: () async {
                await CachedNetworkImage.evictFromCache(widget.photo.url);
                if (mounted) setState(() => _retry++);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('再試行'),
            ),
          ),
        ),
      ),
    );
  }
}

class _StreetViewLabel extends StatelessWidget {
  const _StreetViewLabel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.streetview, color: AppColors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'Street View',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPhoto extends StatelessWidget {
  const _EmptyPhoto();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.brMd,
      child: const AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: AppColors.placeholder,
          child: Center(
            child: Icon(Icons.image_outlined, color: AppColors.iconMuted),
          ),
        ),
      ),
    );
  }
}
