import 'package:flutter/material.dart';

import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';

/// 検索履歴リスト（検索カード内に表示）
class SearchHistoryList extends StatelessWidget {
  final List<String> history;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onDelete;

  /// 「もっと見る」タップ時
  final VoidCallback? onShowMore;

  /// カード内に表示する最大件数
  final int maxVisible;

  const SearchHistoryList({
    super.key,
    required this.history,
    required this.onSelect,
    required this.onDelete,
    this.onShowMore,
    this.maxVisible = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('検索履歴はありません', style: AppTextStyles.hint)),
      );
    }

    final canShowMore = history.length > maxVisible;
    final itemCount = canShowMore ? maxVisible : history.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text('検索履歴', style: AppTextStyles.label),
        ),
        ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final item = history[index];
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading:
                  Icon(Icons.history, color: Colors.grey.shade400, size: 20),
              title: Text(
                item,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                onPressed: () => onDelete(item),
              ),
              onTap: () => onSelect(item),
            );
          },
        ),
        if (canShowMore)
          Center(
            child: TextButton(
              onPressed: onShowMore,
              child: Text(
                '最近の検索履歴をもっと見る',
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }
}
