import 'package:flutter/foundation.dart';

import '../../map/models/anime_spot.dart';

/// しおり作成の下書き（選択中の聖地）をアプリ全体で共有するシングルトン。
/// SpotList・聖地詳細・しおり一覧が同じ選択状態を参照・更新できるようにする。
class ShioriDraft {
  ShioriDraft._();
  static final ShioriDraft instance = ShioriDraft._();

  /// 選択中の聖地リスト（spot_id でユニーク）
  final ValueNotifier<List<Spot>> spots = ValueNotifier<List<Spot>>([]);

  bool contains(String spotId) =>
      spots.value.any((s) => s.spotId == spotId);

  void add(Spot spot) {
    if (contains(spot.spotId)) return;
    spots.value = [...spots.value, spot];
  }

  void remove(String spotId) {
    spots.value = spots.value.where((s) => s.spotId != spotId).toList();
  }

  void toggle(Spot spot) {
    contains(spot.spotId) ? remove(spot.spotId) : add(spot);
  }

  void clear() {
    spots.value = [];
  }
}
