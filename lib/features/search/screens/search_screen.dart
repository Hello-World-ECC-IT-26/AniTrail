import 'package:flutter/material.dart';
import '../widgets/search_results.dart';
import '../widgets/search_overlay.dart';
import '../../spot/screens/spot_list.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/main_buttom_nav.dart';

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
      appBar: const AniTrailAppBar(),

      bottomNavigationBar: MainBottomNav(
        onTap: (index) => Navigator.pop(context, index),
      ),

      body: Column(
        children: [
          // ── 検索バー
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
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
                  fillColor: const Color(0xFFFFFFFF),

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
                ? SearchResults(
                    query: query,
                    onViewSpots: (animeTitle, spotCount) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SpotList(
                            animeTitle: animeTitle,
                            spotCount: spotCount,
                          ),
                        ),
                      );
                    },
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}
