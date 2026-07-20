import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/map/models/anime_spot.dart';
import '../../features/map/services/spot_api.dart';
import '../../features/profile/services/profile_service.dart';
import '../../features/coupon/models/coupon.dart';
import '../../features/home/models/app_event.dart';

class AppDataRepository extends ChangeNotifier {
  AppDataRepository(this._api);

  final SpotApi _api;
  UserProfile? profile;
  int? collectedStampCount;
  List<StampCard> stampCards = const [];
  List<CouponGrant> pendingCouponGrants = const [];
  List<AppEvent> activeEvents = const [];
  bool loading = false;
  Object? error;
  Future<void>? _loadRequest;
  String? _loadedUserId;

  Future<void> load({bool refresh = false}) {
    if (!refresh && _loadRequest != null) return _loadRequest!;
    final request = _load(refresh: refresh);
    _loadRequest = request;
    return request.whenComplete(() {
      if (identical(_loadRequest, request)) _loadRequest = null;
    });
  }

  Future<void> _load({required bool refresh}) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (_loadedUserId != currentUserId) {
      _loadedUserId = currentUserId;
      profile = null;
      collectedStampCount = null;
      stampCards = const [];
      pendingCouponGrants = const [];
      activeEvents = const [];
    }
    if (!refresh && profile == null && stampCards.isEmpty) {
      final cached = await _api.readCachedAppBootstrap();
      if (cached != null) _apply(cached, includePendingCouponGrants: false);
    }
    loading = profile == null && stampCards.isEmpty;
    error = null;
    notifyListeners();
    try {
      _apply(await _api.fetchAppBootstrap());
      unawaited(_api.fetchStampCollections());
    } catch (value) {
      error = value;
      notifyListeners();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _apply(
    Map<String, dynamic> data, {
    bool includePendingCouponGrants = true,
  }) {
    final profileData = data['profile'] as Map<String, dynamic>?;
    profile = profileData == null ? null : UserProfile.fromJson(profileData);
    collectedStampCount = (data['collected_stamp_count'] as num?)?.toInt() ?? 0;
    stampCards = (data['stamp_cards'] as List? ?? const [])
        .map((item) => StampCard.fromJson(item as Map<String, dynamic>))
        .toList();
    activeEvents = (data['active_events'] as List? ?? const [])
        .map((item) => AppEvent.fromJson(item as Map<String, dynamic>))
        .toList();
    if (includePendingCouponGrants) {
      pendingCouponGrants = (data['pending_coupon_grants'] as List? ?? const [])
          .map((item) => CouponGrant.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    notifyListeners();
  }

  Future<void> clear() async {
    _loadedUserId = null;
    profile = null;
    collectedStampCount = null;
    stampCards = const [];
    pendingCouponGrants = const [];
    activeEvents = const [];
    await _api.clearUserCaches();
    notifyListeners();
  }

  void removePendingCouponGrants(Iterable<String> grantIds) {
    final ids = grantIds.toSet();
    pendingCouponGrants = pendingCouponGrants
        .where((grant) => !ids.contains(grant.grantId))
        .toList();
    notifyListeners();
  }
}
