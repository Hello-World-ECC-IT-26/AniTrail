import 'package:flutter/material.dart';
import 'package:AniTrail/widgets/search_results.dart';
import 'package:AniTrail/widgets/search_overlay.dart';
import 'package:AniTrail/widgets/app_bar.dart';
import 'package:AniTrail/widgets/main_buttom_nav.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final controller = TextEditingController();
  final focusNode = FocusNode();

  bool isFocused = false;
  String query = '';

  @override
  void initState() {
    super.initState();

    // フォーカス状態監視（検索バーが選択されているか）
    focusNode.addListener(() {
      setState(() => isFocused = focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    // メモリリーク防止
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _onSelect(String value) {
    controller.text = value;
    focusNode.unfocus();

    setState(() {
      query = value;
      isFocused = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // アプリバー
      appBar: const AniTrailAppBar(showBack: true),

      bottomNavigationBar: MainBottomNav(
        onTap: (index) => Navigator.pop(context, index),
      ),

      body: Column(
        children: [
          // ── 検索バー
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: controller,
              focusNode: focusNode,

              // 入力変更時
              onChanged: (v) => setState(() => query = v),

              // 検索確定時
              onSubmitted: (v) {
                focusNode.unfocus();
                setState(() {
                  query = v;
                  isFocused = false;
                });
              },

              style: const TextStyle(fontSize: 14),

              decoration: InputDecoration(
                hintText: '検索',

                filled: true,
                fillColor: const Color(0xFFF0F0F0),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),

                prefixIcon: const Icon(Icons.search),

                // クリアボタン
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          controller.clear();
                          setState(() => query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // ── 検索候補 / 検索結果 ─────────────────────
          Expanded(
            child: isFocused
                ? SearchOverlay(
                    query: query,
                    onSelect: _onSelect,
                    onDeleteHistory: (index) {},
                  )
                : query.isNotEmpty
                ? SearchResults(query: query)
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}
