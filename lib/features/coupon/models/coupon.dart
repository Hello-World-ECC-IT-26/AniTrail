enum CouponCategory { drinkFood, animeGoods }

enum CouponSort { newest, expires }

class Coupon {
  const Coupon({
    required this.id,
    required this.title,
    required this.category,
    required this.discountPercent,
    required this.description,
    required this.startsAt,
    required this.endsAt,
    required this.unlocked,
    required this.visitedCount,
    required this.totalSpotCount,
    required this.requiredVisitCount,
    required this.remainingCount,
    required this.progressPercent,
    this.repeatable = false,
    this.acquiredCount = 0,
    this.availableCount = 0,
    this.unlockSpotName,
    this.unlockAnimeTitle,
    this.grantId,
    this.grantedAt,
    this.usedAt,
  });

  final String id;
  final String title;
  final CouponCategory category;
  final int discountPercent;
  final String? description;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool unlocked;
  final int visitedCount;
  final int totalSpotCount;
  final int requiredVisitCount;
  final int remainingCount;
  final int progressPercent;
  final bool repeatable;
  final int acquiredCount;
  final int availableCount;
  final String? unlockSpotName;
  final String? unlockAnimeTitle;
  final String? grantId;
  final DateTime? grantedAt;
  final DateTime? usedAt;

  bool get isUsed => unlocked && availableCount == 0 && usedAt != null;
  bool get isAnimeGoods => category == CouponCategory.animeGoods;
  String get categoryLabel => isAnimeGoods ? 'ANIME GOODS' : 'DRINK FOOD';

  factory Coupon.fromJson(Map<String, dynamic> json) => Coupon(
    id: json['id'] as String,
    title: json['title'] as String,
    category: couponCategoryFromApi(json['category'] as String?),
    discountPercent: (json['discount_percent'] as num).toInt(),
    description: json['description'] as String?,
    startsAt: DateTime.parse(json['starts_at'] as String),
    endsAt: DateTime.parse(json['ends_at'] as String),
    unlocked: json['unlocked'] == true,
    visitedCount: (json['visited_count'] as num?)?.toInt() ?? 0,
    totalSpotCount: (json['total_spot_count'] as num?)?.toInt() ?? 0,
    requiredVisitCount: (json['required_visit_count'] as num?)?.toInt() ?? 0,
    remainingCount: (json['remaining_count'] as num?)?.toInt() ?? 0,
    progressPercent: (json['progress_percent'] as num?)?.toInt() ?? 0,
    repeatable: json['repeatable'] == true,
    acquiredCount: (json['acquired_count'] as num?)?.toInt() ?? 0,
    availableCount: (json['available_count'] as num?)?.toInt() ?? 0,
    unlockSpotName: json['unlock_spot_name'] as String?,
    unlockAnimeTitle: json['unlock_anime_title'] as String?,
    grantId: json['grant_id'] as String?,
    grantedAt: DateTime.tryParse(json['granted_at'] as String? ?? ''),
    usedAt: DateTime.tryParse(json['used_at'] as String? ?? ''),
  );

  Coupon copyWith({DateTime? usedAt}) => Coupon(
    id: id,
    title: title,
    category: category,
    discountPercent: discountPercent,
    description: description,
    startsAt: startsAt,
    endsAt: endsAt,
    unlocked: unlocked,
    visitedCount: visitedCount,
    totalSpotCount: totalSpotCount,
    requiredVisitCount: requiredVisitCount,
    remainingCount: remainingCount,
    progressPercent: progressPercent,
    repeatable: repeatable,
    acquiredCount: acquiredCount,
    availableCount: availableCount,
    unlockSpotName: unlockSpotName,
    unlockAnimeTitle: unlockAnimeTitle,
    grantId: grantId,
    grantedAt: grantedAt,
    usedAt: usedAt ?? this.usedAt,
  );
}

class CouponGrant {
  const CouponGrant({
    required this.grantId,
    required this.couponId,
    required this.title,
    required this.category,
    required this.discountPercent,
    required this.endsAt,
    required this.grantedAt,
  });

  final String grantId;
  final String couponId;
  final String title;
  final CouponCategory category;
  final int discountPercent;
  final DateTime endsAt;
  final DateTime grantedAt;

  factory CouponGrant.fromJson(Map<String, dynamic> json) => CouponGrant(
    grantId: json['grant_id'] as String,
    couponId: json['coupon_id'] as String,
    title: json['title'] as String,
    category: couponCategoryFromApi(json['category'] as String?),
    discountPercent: (json['discount_percent'] as num).toInt(),
    endsAt: DateTime.parse(json['ends_at'] as String),
    grantedAt: DateTime.parse(json['granted_at'] as String),
  );
}

class StampCreationResult {
  const StampCreationResult({required this.stampId, required this.newGrants});

  final String stampId;
  final List<CouponGrant> newGrants;
}

CouponCategory couponCategoryFromApi(String? value) => switch (value) {
  'drink_food' => CouponCategory.drinkFood,
  'anime_goods' => CouponCategory.animeGoods,
  _ => throw FormatException('未対応のクーポンカテゴリーです: $value'),
};

String couponCategoryToApi(CouponCategory value) =>
    value == CouponCategory.animeGoods ? 'anime_goods' : 'drink_food';
