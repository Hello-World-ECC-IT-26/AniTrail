import 'package:anitrail/features/map/models/anime_spot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('集約APIのカードと訪問情報を1レスポンスから復元できる', () {
    final collection = StampCollection.fromJson({
      'card_id': 'card-1',
      'title': '君の名は',
      'spot_count': 1,
      'created_at': '2026-07-20T00:00:00Z',
      'spot_details': [
        {'spot_id': 'spot-1', 'name': '諏訪湖と立石公園'},
      ],
      'visit_stats': {
        'spot-1': {
          'visit_count': 2,
          'last_visited_at': '2026-07-20T01:00:00Z',
          'arrival_photo_urls': ['https://example.com/1.jpg'],
        },
      },
    });

    expect(collection.card.spots.single.spotId, 'spot-1');
    expect(collection.visitStats['spot-1']?.count, 2);
    expect(collection.visitStats['spot-1']?.arrivalPhotoUrls, [
      'https://example.com/1.jpg',
    ]);
  });
}
