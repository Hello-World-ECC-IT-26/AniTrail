import 'anime_spot.dart';

bool canTourSpot(Spot spot) {
  final lat = spot.latitude;
  final lng = spot.longitude;
  return lat != null &&
      lng != null &&
      lat.isFinite &&
      lng.isFinite &&
      lat >= -90 &&
      lat <= 90 &&
      lng >= -180 &&
      lng <= 180;
}

/// Only IDs are persisted; names, images and coordinates come from the card.
class TourPlan {
  TourPlan(Iterable<String> spotIds)
    : spotIds = List.unmodifiable(spotIds.toSet());

  final List<String> spotIds;

  List<Spot> resolve(List<Spot> spots) {
    final byId = {
      for (final spot in spots)
        if (canTourSpot(spot)) spot.spotId: spot,
    };
    return [
      for (final id in spotIds)
        if (byId[id] != null) byId[id]!,
    ];
  }
}

/// A navigation session is deliberately not persisted.
class TourProgress {
  TourProgress({
    required List<Spot> spots,
    this.index = 0,
    Set<String> visitedSpotIds = const {},
  }) : spots = List.unmodifiable(spots),
       visitedSpotIds = Set.unmodifiable(visitedSpotIds) {
    if (spots.isEmpty || index < 0 || index >= spots.length) {
      throw ArgumentError('Invalid tour position');
    }
  }

  final List<Spot> spots;
  final int index;
  final Set<String> visitedSpotIds;
  Spot get current => spots[index];
  bool get hasNext => index + 1 < spots.length;
  TourProgress nextAfterArrival() {
    if (!hasNext) throw StateError('Tour is complete');
    return TourProgress(
      spots: spots,
      index: index + 1,
      visitedSpotIds: {...visitedSpotIds, current.spotId},
    );
  }
}
