import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/styles/app_shadows.dart';
import '../../../core/widgets/app_buttons.dart';
import '../models/anime_spot.dart';
import '../services/tour_controller.dart';
import 'tour_map_assets.dart';
import 'spot_list_item.dart';

Color tourColor(int index) =>
    index < 4 ? AppColors.tourRouteColors[index] : AppColors.tourPrimary;

class TourEndpoints extends StatelessWidget {
  const TourEndpoints({super.key, required this.tour});
  final TourController tour;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 16),
        decoration: const BoxDecoration(
          color: AppColors.tourSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SvgPicture.asset(TourMapAssets.smallFlag),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text('スタート地点（現在地）', style: AppTextStyles.caption),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.only(left: 26), child: Divider()),
            Row(
              children: [
                SvgPicture.asset(TourMapAssets.smallPin),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tour.spots.isEmpty ? '目的地の聖地を選択' : tour.spots.last.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Reuses the shiori sheet's scroll controller, including its drag behaviour.
class MapTourPanel extends StatelessWidget {
  const MapTourPanel({
    super.key,
    required this.tour,
    required this.scrollController,
    required this.onClose,
    required this.onSpotDetail,
    required this.onStart,
    this.imageHeaders = const {},
  });
  final TourController tour;
  final ScrollController scrollController;
  final VoidCallback onClose;
  final ValueChanged<Spot> onSpotDetail;
  final VoidCallback onStart;
  final Map<String, String> imageHeaders;

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.tourSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 336),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 19),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '巡る順番を設定しますか？',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.tourText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: '設定',
                  height: 36 * MediaQuery.textScalerOf(context).scale(1),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  backgroundColor: AppColors.tourPrimary,
                  onPressed: () => Navigator.pop(context, true),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'もう少し考える',
                  height: 36 * MediaQuery.textScalerOf(context).scale(1),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed == true) await tour.save();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          IconButton(
            tooltip: tour.editing ? '変更を取り消す' : '聖地一覧に戻る',
            onPressed: tour.saving ? null : onClose,
            icon: SvgPicture.asset(TourMapAssets.back),
          ),
          Expanded(
            child: Text(
              tour.editing ? '聖地の巡る順番を編集' : '聖地の巡る順番',
              textAlign: TextAlign.center,
              style: AppTextStyles.input.copyWith(fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: AppButton(
              label: tour.editing ? '設定' : '編集',
              size: AppButtonSize.compact,
              fullWidth: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              backgroundColor: AppColors.tourPrimary,
              isLoading: tour.saving,
              onPressed: tour.editing
                  ? tour.spots.isEmpty
                        ? null
                        : () => _confirm(context)
                  : tour.canStart
                  ? tour.beginEditing
                  : null,
            ),
          ),
        ],
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Divider(height: 1),
      ),
      if (tour.error != null)
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(tour.error!, style: AppTextStyles.error),
        ),
      if (tour.markerError != null)
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(tour.markerError!, style: AppTextStyles.error),
        ),
      if (tour.routing) const LinearProgressIndicator(),
      if (tour.routeError != null)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text(tour.routeError!, style: AppTextStyles.error)),
            TextButton(onPressed: tour.refreshRoutes, child: const Text('再試行')),
          ],
        ),
      if (tour.spots.isEmpty)
        Expanded(
          child: ListView(
            controller: scrollController,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 100),
                child: Text(
                  '巡りたい聖地を訪問する順にタップしてね',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
              ),
            ],
          ),
        )
      else ...[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            tour.editing ? 'ドラッグで順番を変更できます' : '現在地から順番に案内します',
            style: AppTextStyles.caption.copyWith(fontSize: 11),
          ),
        ),
        Expanded(
          child: tour.editing
              ? ReorderableListView.builder(
                  scrollController: scrollController,
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: tour.spots.length,
                  onReorder: tour.reorder,
                  itemBuilder: (context, i) => _row(i, draggable: true),
                )
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: tour.spots.length,
                  itemBuilder: (context, i) => _row(i),
                ),
        ),
        if (!tour.editing)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: AppButton(
                label: 'ナビ開始',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                onPressed:
                    tour.canStart &&
                        !tour.routing &&
                        tour.routeError == null &&
                        tour.legs.length == tour.spots.length
                    ? onStart
                    : null,
              ),
            ),
          ),
      ],
    ],
  );

  Widget _row(int i, {bool draggable = false}) {
    final spot = tour.spots[i];
    final route = i < tour.legs.length ? tour.legs[i] : null;
    final distance = route?.distanceMeters;
    final seconds = route?.durationSeconds;
    final detail = distance == null || seconds == null
        ? '徒歩ルート未取得'
        : '徒歩で${(seconds / 60).ceil()}分 (${(distance / 1000).toStringAsFixed(1)}km)';
    final row = Padding(
      key: ValueKey(spot.spotId),
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: i == 0 ? AppColors.tourPrimary : tourColor(i),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      color: i == 0 ? AppColors.tourPrimary : tourColor(i),
                    ),
                  ),
                ),
                if (draggable)
                  ReorderableDragStartListener(
                    index: i,
                    enabled: !tour.saving,
                    child: Container(
                      color: Colors.transparent,
                      height: 48,
                      width: 26,
                      alignment: Alignment.center,
                      child: SvgPicture.asset(TourMapAssets.drag),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: AppColors.tourSurface,
              borderRadius: BorderRadius.circular(4),
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: draggable ? null : () => onSpotDetail(spot),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.tourSurface,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    boxShadow: AppShadows.card,
                  ),
                  child: SpotListItem(
                    spot: spot,
                    animeTitle: spot.animeTitle ?? '',
                    showDistance: false,
                    routeDescription: detail,
                    thumbnailSize: const Size(112, 82),
                    padding: EdgeInsets.zero,
                    imageHeaders: imageHeaders,
                    onTap: draggable ? null : () => onSpotDetail(spot),
                    trailing: draggable
                        ? IconButton(
                            tooltip: '巡回から外す',
                            onPressed: tour.saving
                                ? null
                                : () => tour.toggle(spot),
                            icon: const Icon(Icons.close, size: 16),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(8),
                            child: SvgPicture.asset(TourMapAssets.next),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return row;
  }
}
