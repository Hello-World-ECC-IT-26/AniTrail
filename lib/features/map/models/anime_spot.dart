// マップ検索結果のデータモデル（Hono バックエンドの /animes・/spots から取得）

/// 聖地（スポット）
class Spot {
  final String spotId;
  final String name;
  final double? latitude;
  final double? longitude;

  /// 現在地からの距離（メートル）。lat/lng 指定で検索した場合に入る
  final double? distanceM;

  final String? city;
  final String? address;
  final String? image;

  /// DB に保存された Street View の共有 URL（ブラウザ用）
  final String? streetViewUrl;

  /// DB に保存された Street View Static API の画像 URL（表示用）
  final String? streetViewImageUrl;

  /// Workers キャッシュプロキシ経由の Street View 画像 URL（表示用・優先）
  final String? streetViewProxyUrl;

  /// 訪問済みか（認証ユーザーの user_spot_visits 由来）
  final bool visited;

  const Spot({
    required this.spotId,
    required this.name,
    this.latitude,
    this.longitude,
    this.distanceM,
    this.city,
    this.address,
    this.image,
    this.streetViewUrl,
    this.streetViewImageUrl,
    this.streetViewProxyUrl,
    this.visited = false,
  });

  /// 距離表示用（例: 1.5km / 800m）。未取得なら空文字
  String get distanceText {
    final m = distanceM;
    if (m == null) return '';
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)}km';
    return '${m.round()}m';
  }

  /// 住所表示用（address 優先、無ければ city）
  String get addressText => address ?? city ?? '';

  factory Spot.fromJson(Map<String, dynamic> json, {String? baseUrl}) {
    double? toDouble(dynamic v) =>
        v == null ? null : (v as num).toDouble();
    final lat = toDouble(json['latitude']);
    final lng = toDouble(json['longitude']);
    String? proxyUrl;
    if (baseUrl != null && lat != null && lng != null) {
      proxyUrl = '$baseUrl/street-view/image?lat=$lat&lng=$lng';
    }
    return Spot(
      spotId: json['spot_id'] as String,
      name: (json['name'] as String?) ?? '',
      latitude: lat,
      longitude: lng,
      distanceM: toDouble(json['distance_m']),
      city: json['city'] as String?,
      address: json['address'] as String?,
      image: json['image'] as String?,
      streetViewUrl: json['street_view_url'] as String?,
      streetViewImageUrl: json['street_view_image_url'] as String?,
      streetViewProxyUrl: proxyUrl,
      visited: (json['visited'] as bool?) ?? false,
    );
  }
}

/// アニメ一覧画面のスポットプレビュー（lat/lng + street_view_image_url のみ）
class SpotPreview {
  final String spotId;
  final double? latitude;
  final double? longitude;
  final String? streetViewImageUrl;

  const SpotPreview({
    required this.spotId,
    this.latitude,
    this.longitude,
    this.streetViewImageUrl,
  });

  factory SpotPreview.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) => v == null ? null : (v as num).toDouble();
    return SpotPreview(
      spotId: json['spot_id'] as String,
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
      streetViewImageUrl: json['street_view_image_url'] as String?,
    );
  }

  String? proxyUrl(String baseUrl) {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return null;
    return '$baseUrl/street-view/image?lat=$lat&lng=$lng';
  }
}

/// アニメ作品（検索結果の1件）
class AnimeResult {
  final String animeId;
  final String title;
  final int spotCount;

  /// Annict + Jikan 由来のキービジュアル URL（横画像）
  final String? keyVisualUrl;

  /// アニメ一覧画面用のスポットプレビュー（最大4件）
  final List<SpotPreview> spotPreview;

  /// 聖地一覧（アニメ選択時に /spots から取得して詰める）
  List<Spot> spots;

  AnimeResult({
    required this.animeId,
    required this.title,
    required this.spotCount,
    this.keyVisualUrl,
    List<SpotPreview>? spotPreview,
    List<Spot>? spots,
  })  : spotPreview = spotPreview ?? [],
        spots = spots ?? [];

  factory AnimeResult.fromJson(Map<String, dynamic> json, {String? baseUrl}) {
    final annict = json['annict'] as Map<String, dynamic>?;
    final previewList = (json['spot_preview'] as List? ?? [])
        .map((e) => SpotPreview.fromJson(e as Map<String, dynamic>))
        .toList();
    return AnimeResult(
      animeId: json['anime_id'] as String,
      title: (json['title'] as String?) ?? '（タイトル不明）',
      spotCount: (json['spot_count'] as num?)?.toInt() ?? 0,
      keyVisualUrl: annict?['keyVisualUrl'] as String?,
      spotPreview: previewList,
    );
  }
}
