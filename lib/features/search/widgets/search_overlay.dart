import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/styles/app_styles.dart';
import '../../map/services/spot_api.dart';

class SearchOverlay extends StatefulWidget {
  /// 現在の検索クエリ
  final String query;

  /// 候補・履歴タップ時のコールバック（選択したテキストを渡す）
  final ValueChanged<String> onSelect;

  /// 履歴削除ボタンタップ時のコールバック
  final ValueChanged<String> onDeleteHistory;

  /// 保存済みの検索履歴（新しい順）
  final List<String> history;

  const SearchOverlay({
    super.key,
    required this.query,
    required this.onSelect,
    required this.onDeleteHistory,
    required this.history,
  });

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final SpotApi _api = SpotApi();
  Timer? _debounce;
  List<String> _suggestions = [];
  bool _loading = false;
  int _requestId = 0;

  // queryが空でなければ予測ワードモード
  bool get _isTyping => widget.query.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _scheduleSuggestions();
  }

  @override
  void didUpdateWidget(SearchOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) _scheduleSuggestions();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleSuggestions() {
    _debounce?.cancel();
    final query = widget.query.trim();
    final requestId = ++_requestId;
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final suggestions = await _api.searchAnimeSuggestions(query);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _suggestions = suggestions;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ラベル（履歴 or 予測ワード）
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                _isTyping ? 'お好みのアニメはこちらですか？' : '検索履歴',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            _isTyping ? _buildSuggestions() : _buildHistory(),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // 検索履歴リスト
  Widget _buildHistory() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.history.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
      itemBuilder: (context, index) {
        final text = widget.history[index];
        return ListTile(
          dense: true,
          leading: Icon(Icons.history, color: Colors.grey.shade400, size: 18),
          title: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
            onPressed: () => widget.onDeleteHistory(text),
          ),
          onTap: () => widget.onSelect(text),
        );
      },
    );
  }

  // 予測ワードリスト
  Widget _buildSuggestions() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_suggestions.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 21,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '一致するアニメがありません',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '別のキーワードで検索してみてください',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _suggestions.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
      itemBuilder: (context, index) {
        final text = _suggestions[index];
        return ListTile(
          dense: true,
          leading: Icon(Icons.search, color: Colors.grey.shade400, size: 18),
          title: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              children: _highlight(text, widget.query),
            ),
          ),
          onTap: () => widget.onSelect(text),
        );
      },
    );
  }

  // 検索クエリにマッチした文字を青くハイライトする
  List<TextSpan> _highlight(String text, String query) {
    final idx = text.toLowerCase().indexOf(query.toLowerCase());
    if (idx == -1) return [TextSpan(text: text)];
    return [
      TextSpan(text: text.substring(0, idx)),
      TextSpan(
        text: text.substring(idx, idx + query.length),
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      TextSpan(text: text.substring(idx + query.length)),
    ];
  }
}
