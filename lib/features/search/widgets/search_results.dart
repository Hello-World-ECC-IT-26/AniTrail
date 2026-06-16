import 'package:flutter/material.dart';
import 'search_result_card.dart';

class SearchResults extends StatelessWidget {
  final String query;
  final void Function(String title, int spotCount)? onViewSpots;

  const SearchResults({super.key, required this.query, this.onViewSpots});
  @override
  Widget build(BuildContext context) {
    // ダミーの件数（実装時はSupabaseから取得した件数を使用）
    const int resultCount = 4;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: resultCount + 1,
      itemBuilder: (_, index) {
        // index 0: 件数テキスト
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '$resultCount件のアニメが見つかりました',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          );
        }

        // index 1以降: 検索結果カード
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SearchResultCard(
            title: '君の名は。',
            spotCount: 10,
            onViewSpots: () {
              onViewSpots?.call('君の名は。', 10);
            },
          ),
        );
      },
    );
  }
}
