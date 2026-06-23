import 'package:flutter/material.dart';

import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/styles/app_dimens.dart';
import 'search_history_list.dart';

/// マップ上に浮く検索カード（検索バータップ時に表示）。
class MapSearchPanel extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> history;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String> onSelectHistory;
  final ValueChanged<String> onDeleteHistory;
  final VoidCallback? onShowMore;

  const MapSearchPanel({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.history,
    required this.onBack,
    required this.onSubmit,
    required this.onClear,
    required this.onSelectHistory,
    required this.onDeleteHistory,
    this.onChanged,
    this.onShowMore,
  });

  @override
  State<MapSearchPanel> createState() => _MapSearchPanelState();
}

class _MapSearchPanelState extends State<MapSearchPanel> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    widget.onChanged?.call(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + AppSpacing.md,
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      child: Material(
        elevation: 4,
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: AppColors.textSecondary,
                    onPressed: widget.onBack,
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => widget.onSubmit(),
                      decoration: const InputDecoration(
                        hintText: 'ここで検索',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: AppTextStyles.input,
                    ),
                  ),
                  if (_hasText)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: AppColors.textSecondary,
                      onPressed: widget.onClear,
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.search),
                      color: AppColors.textSecondary,
                      onPressed: widget.onSubmit,
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            SearchHistoryList(
              history: widget.history,
              onSelect: widget.onSelectHistory,
              onDelete: widget.onDeleteHistory,
              onShowMore: widget.onShowMore,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
