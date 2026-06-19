import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/anime_spot.dart';
import '../services/spot_api.dart';

/// 検索・履歴・アニメ/聖地の取得ロジックを担当するミックスイン。
/// MapLocationMixin と一緒に使うことを前提に hasFix / currentLatLng を参照する。
mixin MapSearchMixin<T extends StatefulWidget> on State<T> {
  final SpotApi spotApi = SpotApi();

  bool searchVisible = false;
  bool resultsVisible = false;
  String displayQuery = '';
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();
  List<String> history = [];
  int filterIndex = 0;
  int sortIndex = 0;
  AnimeResult? selectedAnime;

  List<AnimeResult> results = [];
  bool loading = false;
  bool spotsLoading = false;
  String? searchError;

  static const _historyKey = 'search_history';

  // ミックスイン利用側が提供するゲッター
  bool get hasFix;
  double get currentLat;
  double get currentLng;

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() { history = prefs.getStringList(_historyKey) ?? []; });
  }

  Future<void> saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, history.take(20).toList());
  }

  void openSearch() {
    searchController.text = displayQuery;
    setState(() => searchVisible = true);
    searchFocus.requestFocus();
  }

  void closeSearch() {
    searchController.clear();
    searchFocus.unfocus();
    setState(() {
      searchVisible = false;
      resultsVisible = false;
      displayQuery = '';
      selectedAnime = null;
      filterIndex = 0;
      results = [];
      loading = false;
      searchError = null;
    });
  }

  void clearSearchInput() {
    searchController.clear();
    setState(() {});
    searchFocus.requestFocus();
  }

  Future<void> submitSearch() async {
    final q = searchController.text.trim();
    if (q.isEmpty) return;
    setState(() {
      history = [q, ...history.where((h) => h != q)];
      displayQuery = q;
      searchVisible = false;
      resultsVisible = true;
      filterIndex = 0;
      selectedAnime = null;
      results = [];
      loading = true;
      searchError = null;
    });
    saveHistory();
    searchFocus.unfocus();

    try {
      final r = await spotApi.searchAnimes(q);
      if (!mounted) return;
      setState(() { results = r; loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { loading = false; searchError = '検索に失敗しました。通信環境を確認してください。'; });
    }
  }

  void selectHistory(String item) {
    searchController.text = item;
    submitSearch();
  }

  Future<void> selectAnime(AnimeResult anime) async {
    setState(() { selectedAnime = anime; filterIndex = 0; });
    if (anime.spots.isNotEmpty) return;

    setState(() => spotsLoading = true);
    try {
      final spots = await spotApi.fetchSpots(
        anime.animeId,
        lat: hasFix ? currentLat : null,
        lng: hasFix ? currentLng : null,
      );
      if (!mounted) return;
      setState(() { anime.spots = spots; spotsLoading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { spotsLoading = false; searchError = '聖地の取得に失敗しました。'; });
    }
  }

  void disposeSearch() {
    searchController.dispose();
    searchFocus.dispose();
  }
}
