import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/map/models/anime_spot.dart';
import '../../features/map/services/spot_api.dart';
import '../../features/profile/services/profile_service.dart';

class AppDataRepository extends ChangeNotifier {
  AppDataRepository(this._api);

  final SpotApi _api;
  UserProfile? profile;
  int? collectedStampCount;
  List<StampCard> stampCards = const [];
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
    }
    if (!refresh && profile == null && stampCards.isEmpty) {
      final cached = await _api.readCachedAppBootstrap();
      if (cached != null) _apply(cached);
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

  void _apply(Map<String, dynamic> data) {
    final profileData = data['profile'] as Map<String, dynamic>?;
    profile = profileData == null ? null : UserProfile.fromJson(profileData);
    collectedStampCount = (data['collected_stamp_count'] as num?)?.toInt() ?? 0;
    stampCards = (data['stamp_cards'] as List? ?? const [])
        .map((item) => StampCard.fromJson(item as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> clear() async {
    _loadedUserId = null;
    profile = null;
    collectedStampCount = null;
    stampCards = const [];
    await _api.clearUserCaches();
    notifyListeners();
  }
}
