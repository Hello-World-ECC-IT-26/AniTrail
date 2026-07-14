import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/widgets/loading_screen.dart';
import '../../../core/styles/app_dimens.dart';
import '../../map/models/anime_spot.dart';
import '../../map/services/spot_api.dart';
import 'search_result_card.dart';

class SearchResults extends StatefulWidget {
  final String query;

  /// 聖地一覧へ遷移（animeId・タイトル・聖地数・キービジュアルURL を渡す）
  final void Function(
    String animeId,
    String title,
    int spotCount,
    String? keyVisualUrl,
  )?
  onViewSpots;

  const SearchResults({super.key, required this.query, this.onViewSpots});

  @override
  State<SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends State<SearchResults> {
  final SpotApi _api = SpotApi();

  List<AnimeResult> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void didUpdateWidget(SearchResults old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query) _search();
  }

  Future<void> _search() async {
    final q = widget.query.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await _api.searchAnimes(q);
      if (!mounted) return;
      for (final anime in results.take(3)) {
        unawaited(
          _api.fetchSpots(anime.animeId).then<void>((_) {}, onError: (_, _) {}),
        );
      }
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '検索に失敗しました。通信環境を確認してください。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppLoadingScreen(message: '検索中・・・');
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: AppColors.textMuted),
        ),
      );
    }
    if (_results.isEmpty) {
      return const Center(
        child: Text('該当するアニメが見つかりませんでした', style: AppTextStyles.hint),
      );
    }

    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final headers = token != null
        ? {'Authorization': 'Bearer $token'}
        : <String, String>{};
    final baseUrl = (dotenv.env['API_BASE_URL'] ?? '').replaceAll(
      RegExp(r'/$'),
      '',
    );

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      itemCount: _results.length + 1,
      itemBuilder: (_, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              '${_results.length}件のアニメが見つかりました',
              textAlign: TextAlign.center,
              style: AppTextStyles.hint,
            ),
          );
        }

        final anime = _results[index - 1];
        final previewUrls = anime.spotPreview
            .map((p) => p.proxyUrl(baseUrl))
            .whereType<String>()
            .toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: SearchResultCard(
            title: anime.title,
            bannerImage: anime.keyVisualUrl,
            spotCount: anime.spotCount,
            spotImages: previewUrls,
            httpHeaders: headers,
            onViewSpots: () => widget.onViewSpots?.call(
              anime.animeId,
              anime.title,
              anime.spotCount,
              anime.keyVisualUrl,
            ),
          ),
        );
      },
    );
  }
}
