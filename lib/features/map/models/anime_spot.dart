// マップ検索結果のデータモデル（Hono バックエンドの /animes・/spots から取得）

/// 聖地（スポット）
class Spot {
  final String spotId;
  final String name;
  final String? animeId;
  final String? animeTitle;
  final String? keyVisualUrl;
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

  /// 登場話数（あれば）
  final int? episode;

  const Spot({
    required this.spotId,
    required this.name,
    this.animeId,
    this.animeTitle,
    this.keyVisualUrl,
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
    this.episode,
  });

  /// 登場シーンの説明（例: 第3話に登場したシーン）。episode が無ければ空文字
  String get sceneText => episode != null ? '第$episode話に登場したシーン' : '';

  /// 距離表示用（例: 1.5km / 800m）。未取得なら空文字
  String get distanceText {
    final m = distanceM;
    if (m == null) return '';
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)}km';
    return '${m.round()}m';
  }

  /// 住所表示用（address 優先、無ければ city）
  String get addressText => address ?? city ?? '';

  Spot withAnime({
    required String animeId,
    required String animeTitle,
    String? keyVisualUrl,
  }) => Spot(
    spotId: spotId,
    name: name,
    animeId: animeId,
    animeTitle: animeTitle,
    keyVisualUrl: keyVisualUrl,
    latitude: latitude,
    longitude: longitude,
    distanceM: distanceM,
    city: city,
    address: address,
    image: image,
    streetViewUrl: streetViewUrl,
    streetViewImageUrl: streetViewImageUrl,
    streetViewProxyUrl: streetViewProxyUrl,
    visited: visited,
    episode: episode,
  );

  factory Spot.fromJson(Map<String, dynamic> json, {String? baseUrl}) {
    double? toDouble(dynamic v) => v == null ? null : (v as num).toDouble();
    final lat = toDouble(json['latitude']);
    final lng = toDouble(json['longitude']);
    String? proxyUrl;
    if (baseUrl != null && lat != null && lng != null) {
      proxyUrl = '$baseUrl/street-view/image?lat=$lat&lng=$lng';
    }
    return Spot(
      spotId: json['spot_id'] as String,
      name: (json['name'] as String?) ?? '',
      animeId: json['anime_id'] as String?,
      animeTitle: json['anime_title'] as String?,
      keyVisualUrl: json['key_visual_url'] as String?,
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
      episode: (json['episode'] as num?)?.toInt(),
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

/// しおり（スタンプカード）。ホームの「作成した旅のしおり」一覧で使用。
class StampCard {
  final String cardId;
  final String title;
  final int spotCount;
  final List<String> spotImageUrls;
  final List<String> keyVisualUrls;
  final List<Spot> spots;
  final DateTime? createdAt;

  const StampCard({
    required this.cardId,
    required this.title,
    required this.spotCount,
    this.spotImageUrls = const [],
    this.keyVisualUrls = const [],
    this.spots = const [],
    this.createdAt,
  });

  factory StampCard.fromJson(Map<String, dynamic> json, {String? baseUrl}) {
    final t = json['title'] as String?;
    return StampCard(
      cardId: json['card_id'] as String,
      title: (t != null && t.isNotEmpty) ? t : 'しおりタイトル',
      spotCount: (json['spot_count'] as num?)?.toInt() ?? 0,
      spotImageUrls: ((json['spot_image_urls'] as List?) ?? [])
          .map((e) => e as String?)
          .whereType<String>()
          .toList(),
      keyVisualUrls: ((json['key_visual_urls'] as List?) ?? [])
          .whereType<String>()
          .toList(),
      spots: ((json['spot_details'] as List?) ?? [])
          .map(
            (e) => Spot.fromJson(e as Map<String, dynamic>, baseUrl: baseUrl),
          )
          .toList(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
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
  }) : spotPreview = spotPreview ?? [],
       spots = spots ?? [];

  factory AnimeResult.fromJson(Map<String, dynamic> json, {String? baseUrl}) {
    Map<String, dynamic>? asMap(dynamic value) =>
        value is Map<String, dynamic> ? value : null;

    String? nonEmptyString(dynamic value) {
      if (value is! String) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    final annict = asMap(json['annict']);
    final jikan = asMap(json['jikan']);
    final images = asMap(jikan?['images']) ?? asMap(json['images']);
    final webp = asMap(images?['webp']);
    final jpg = asMap(images?['jpg']);

    final keyVisualUrl = [
      nonEmptyString(json['keyVisualUrl']),
      nonEmptyString(json['key_visual_url']),
      nonEmptyString(annict?['keyVisualUrl']),
      nonEmptyString(annict?['key_visual_url']),
      nonEmptyString(jikan?['keyVisualUrl']),
      nonEmptyString(jikan?['key_visual_url']),
      nonEmptyString(webp?['large_image_url']),
      nonEmptyString(jpg?['large_image_url']),
      nonEmptyString(webp?['image_url']),
      nonEmptyString(jpg?['image_url']),
      nonEmptyString(jikan?['image_url']),
      nonEmptyString(json['image_url']),
    ].whereType<String>().firstOrNull;

    final previewList = (json['spot_preview'] as List? ?? [])
        .map((e) => SpotPreview.fromJson(e as Map<String, dynamic>))
        .toList();
    return AnimeResult(
      animeId: json['anime_id'] as String,
      title: (json['title'] as String?) ?? '（タイトル不明）',
      spotCount: (json['spot_count'] as num?)?.toInt() ?? 0,
      keyVisualUrl: keyVisualUrl,
      spotPreview: previewList,
    );
  }
}
