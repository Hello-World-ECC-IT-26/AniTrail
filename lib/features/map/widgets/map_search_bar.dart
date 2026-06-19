import 'package:flutter/material.dart';

import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';

/// マップ上部の折りたたみ検索バー + しおりボタン
class MapSearchBar extends StatelessWidget {
  /// 現在の検索クエリ（空ならプレースホルダー表示）
  final String query;

  /// 検索バータップ時（検索パネルを開く）
  final VoidCallback onTap;

  /// しおりボタンタップ時
  final VoidCallback onShioriTap;

  /// しおりボタンを表示するか（結果シート表示中は隠す）
  final bool showShiori;

  /// 結果表示中に表示する戻るボタンのコールバック（null のとき通常モード）
  final VoidCallback? onBack;

  const MapSearchBar({
    super.key,
    required this.query,
    required this.onTap,
    required this.onShioriTap,
    this.showShiori = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    if (onBack != null)
                      GestureDetector(
                        onTap: onBack,
                        child: const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.arrow_back,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    else ...[
                      Icon(Icons.location_on_outlined, color: AppColors.primary),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: GestureDetector(
                        onTap: onTap,
                        child: Text(
                          query.isEmpty ? 'ここで検索' : query,
                          style: query.isEmpty
                              ? AppTextStyles.hint
                              : AppTextStyles.input,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (onBack == null)
                      Icon(Icons.search, color: AppColors.textSecondary),
                  ],
                ),
              ),
          ),
          if (showShiori) ...[
            const SizedBox(height: 8),
            FloatingActionButton.small(
              backgroundColor: AppColors.primary,
              heroTag: 'shiori',
              onPressed: onShioriTap,
              child: const Icon(Icons.bookmark_outline, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
