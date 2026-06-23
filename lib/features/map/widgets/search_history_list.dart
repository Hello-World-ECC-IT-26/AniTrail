import 'package:flutter/material.dart';

import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/styles/app_dimens.dart';

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
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
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
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
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
                  const Icon(Icons.history, color: AppColors.iconMuted, size: 20),
              title: Text(
                item,
                style: AppTextStyles.input.copyWith(fontWeight: FontWeight.w600),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 16, color: AppColors.iconMuted),
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
