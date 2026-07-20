import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/api_http_client.dart';
import '../models/coupon.dart';

class CouponRepository extends ChangeNotifier {
  CouponRepository({http.Client? client})
    : _client = client ?? ApiHttpClient.shared;

  final http.Client _client;
  List<Coupon> coupons = const [];
  CouponSort sort = CouponSort.newest;
  CouponCategory? category;
  Object? error;
  bool loading = false;
  bool initialized = false;
  Future<void>? _request;
  String? _userId;
  final Set<String> _usingCouponIds = {};

  bool isUsing(String couponId) => _usingCouponIds.contains(couponId);

  String get _baseUrl {
    final value = dotenv.env['API_BASE_URL'];
    if (value == null || value.isEmpty) {
      throw StateError('API_BASE_URL が .env に設定されていません');
    }
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  Map<String, String> get _headers {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) throw StateError('クーポンの取得にはログインが必要です');
    return {'Authorization': 'Bearer $token'};
  }

  Future<void> load({bool refresh = false}) {
    if (!refresh && initialized) return Future.value();
    if (_request != null) return _request!;
    final request = _load();
    _request = request;
    return request.whenComplete(() {
      if (identical(_request, request)) _request = null;
    });
  }

  Future<void> _load() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (_userId != currentUserId) {
      _userId = currentUserId;
      coupons = const [];
      initialized = false;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      final params = <String, String>{
        'sort': sort == CouponSort.expires ? 'expires' : 'newest',
        if (category != null) 'category': couponCategoryToApi(category!),
      };
      final response = await _client.get(
        Uri.parse('$_baseUrl/coupons/me').replace(queryParameters: params),
        headers: _headers,
      );
      if (response.statusCode != 200) {
        throw Exception('クーポンを読み込めませんでした (${response.statusCode})');
      }
      final body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      coupons = (body['data'] as List? ?? const [])
          .map((item) => Coupon.fromJson(item as Map<String, dynamic>))
          .toList();
      initialized = true;
    } catch (value) {
      error = value;
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> setSort(CouponSort value) async {
    sort = value;
    initialized = false;
    await load(refresh: true);
  }

  Future<void> setCategory(CouponCategory? value) async {
    category = value;
    initialized = false;
    await load(refresh: true);
  }

  Future<void> useCoupon(String couponId) async {
    if (_usingCouponIds.contains(couponId)) return;
    _usingCouponIds.add(couponId);
    notifyListeners();
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/coupons/$couponId/use'),
        headers: _headers,
      );
      if (response.statusCode != 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        final detail = body is Map ? body['error']?.toString() : null;
        throw Exception(detail ?? 'クーポンを利用できませんでした');
      }
      final now = DateTime.now();
      coupons = coupons
          .map(
            (coupon) =>
                coupon.id == couponId ? coupon.copyWith(usedAt: now) : coupon,
          )
          .toList();
    } finally {
      _usingCouponIds.remove(couponId);
      notifyListeners();
    }
  }

  Future<void> markGrantSeen(String grantId) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/coupons/grants/$grantId/seen'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('クーポン獲得通知を確認済みにできませんでした');
    }
  }

  void clear() {
    _userId = null;
    coupons = const [];
    initialized = false;
    error = null;
    notifyListeners();
  }
}
