import 'package:flutter/material.dart';
import 'package:AniTrail/widgets/search_result_card.dart';
import 'package:AniTrail/styles/app_styles.dart';

class SearchResults extends StatelessWidget {
  final String query;

  const SearchResults({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 検索結果カード一覧
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: 5,
          itemBuilder: (_, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SearchResultCard(
                title: '君の名は。',
                place: '須賀神社',
                address: '東京都新宿区須賀町5-6',
              ),
            );
          },
        ),

        // 旅のしおりを作成ボタン（左下に固定表示）
        Positioned(
          left: 16,
          bottom: 16,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: しおり作成画面へ
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 4,
            ),
            icon: const Icon(Icons.location_on_outlined, size: 18),
            label: const Text(
              '旅のしおりを作成',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
