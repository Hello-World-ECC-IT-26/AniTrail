import 'package:flutter/material.dart';
import '../../../core/styles/app_styles.dart';

/// 検索バーフォーカス中に表示されるオーバーレイ
/// 動作:
/// - query が空 → 検索履歴を表示
/// - query に文字あり → 予測ワードを表示（マッチ部分を青くハイライト）
class SearchOverlay extends StatefulWidget {
  /// 現在の検索クエリ
  final String query;

  /// 候補・履歴タップ時のコールバック（選択したテキストを渡す）
  final ValueChanged<String> onSelect;

  /// 履歴削除ボタンタップ時のコールバック
  final ValueChanged<String> onDeleteHistory;

  const SearchOverlay({
    super.key,
    required this.query,
    required this.onSelect,
    required this.onDeleteHistory,
  });

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  // 検索履歴（ダミーデータ。実装時はローカルストレージから取得）
  List<String> _history = ['呪術廻戦', '名探偵コナン', '鬼滅の刃'];

  // 予測ワード候補（ダミーデータ。実装時はSupabaseから取得）
  final List<Map<String, dynamic>> _suggestions = [
    {'text': 'アンパンマン', 'icon': Icons.search},
    {'text': '名探偵コナン', 'icon': Icons.history},
    {'text': '鬼滅の刃', 'icon': Icons.history},
    {'text': 'あの日見た花の名前を僕達はまだ知らない', 'icon': Icons.trending_up},
  ];

  // queryが空でなければ予測ワードモード
  bool get _isTyping => widget.query.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
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
      ),
    );
  }

  // 検索履歴リスト
  Widget _buildHistory() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _history.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
      itemBuilder: (context, index) {
        final text = _history[index];
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
            onPressed: () {
              setState(() => _history.remove(text));
              widget.onDeleteHistory(text);
            },
          ),
          onTap: () => widget.onSelect(text),
        );
      },
    );
  }

  // 予測ワードリスト
  Widget _buildSuggestions() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _suggestions.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
      itemBuilder: (context, index) {
        final s = _suggestions[index];
        final text = s['text'] as String;
        return ListTile(
          dense: true,
          leading: Icon(
            s['icon'] as IconData,
            color: Colors.grey.shade400,
            size: 18,
          ),
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
