import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/search_results.dart';
import '../widgets/search_overlay.dart';
import '../../spot/screens/spot_list.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_input.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/main_buttom_nav.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _historyKey = 'search_history';

  final controller = TextEditingController();
  final focusNode = FocusNode();

  bool isFocused = false;
  String query = '';
  List<String> history = [];

  @override
  void initState() {
    super.initState();

    // フォーカス状態監視（検索バーが選択されているか）
    focusNode.addListener(() {
      if (mounted) setState(() => isFocused = focusNode.hasFocus);
    });
    _loadHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    // メモリリーク防止
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => history = prefs.getStringList(_historyKey) ?? []);
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, history.take(20).toList());
  }

  void _addHistory(String value) {
    final q = value.trim();
    if (q.isEmpty) return;
    setState(() => history = [q, ...history.where((item) => item != q)]);
    _saveHistory();
  }

  void _deleteHistory(String value) {
    setState(() => history.remove(value));
    _saveHistory();
  }

  void _onSelect(String value) {
    controller.text = value;
    focusNode.unfocus();
    _addHistory(value);

    setState(() {
      query = value;
      isFocused = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // アプリバー
      appBar: const AniTrailAppBar(),

      bottomNavigationBar: MainBottomNav(
        onTap: (index) => Navigator.pop(context, index),
      ),

      body: Column(
        children: [
          // ── 検索バー
          Padding(
<<<<<<< HEAD
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
=======
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
>>>>>>> 96a751cfc876f6f3e1418e26a981850b939dbba1

                // 入力変更時
                onChanged: (v) => setState(() => query = v),

<<<<<<< HEAD
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
=======
              // 検索確定時
              onSubmitted: (v) {
                final submitted = v.trim();
                if (submitted.isEmpty) return;
                focusNode.unfocus();
                _addHistory(submitted);
                setState(() {
                  query = submitted;
                  isFocused = false;
                });
              },

              style: AppTextStyles.input,

              decoration: AppInputDecorations.filled(
                hintText: '検索',
                prefixIcon: Icons.search,
                fillColor: AppColors.surfaceMuted,
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
>>>>>>> 96a751cfc876f6f3e1418e26a981850b939dbba1
              ),
            ),
          ),

          // ── 検索候補 / 検索結果 ─────────────────────
          Expanded(
            child: isFocused
                ? SearchOverlay(
                    query: query,
                    history: history,
                    onSelect: _onSelect,
                    onDeleteHistory: _deleteHistory,
                  )
                : query.isNotEmpty
                ? SearchResults(
                    query: query,
                    onViewSpots:
                        (animeId, animeTitle, spotCount, keyVisualUrl) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SpotList(
                                animeId: animeId,
                                animeTitle: animeTitle,
                                spotCount: spotCount,
                                bannerImageUrl: keyVisualUrl,
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
