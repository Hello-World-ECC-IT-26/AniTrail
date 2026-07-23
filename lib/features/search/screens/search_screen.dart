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
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.brMd,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: (v) => setState(() => query = v),
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
                      fillColor: Colors.white,
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                controller.clear();
                                setState(() => query = '');
                              },
                            )
                          : const Icon(
                              Icons.search,
                              color: AppColors.iconMuted,
                            ),
                    ),
                  ),

                  if (isFocused)
                    SearchOverlay(
                      query: query,
                      history: history,
                      onSelect: _onSelect,
                      onDeleteHistory: _deleteHistory,
                    ),
                ],
              ),
            ),
          ),

          if (!isFocused)
            Expanded(
              child: query.isNotEmpty
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
