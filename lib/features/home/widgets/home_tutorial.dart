import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
// import 'package:shared_preferences/shared_preferences.dart';

class TutorialDialog extends StatefulWidget {
  const TutorialDialog({super.key});

  @override
  State<TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<TutorialDialog> {
  final PageController _controller = PageController();

  int _currentPage = 0;

  final List<_TutorialItem> _pages = [
    _TutorialItem(
      title: "AniTrailへようこそ！",
      description: "このアプリは、行きたいアニメの聖地を巡りながら、スタンプラリー形式で楽しめる聖地巡礼アプリになっています！",
      image: "assets/images/home_tutorial1.svg",
    ),
    _TutorialItem(
      title: "聖地検索、カード作成",
      description:
          "好きなアニメの聖地を検索して自由に組み合わせ、自分だけの巡礼スタンプカードを作成できます。スタンプを集めながら聖地巡礼を楽しみましょう！",
      image: "assets/images/home_tutorial2.svg",
    ),
    _TutorialItem(
      title: "探索しながら聖地巡礼",
      description:
          "マップでルートや距離を確認しながら移動できます。聖地付近では方位磁石モードに切り替わり、自分の足で聖地を探し出すワクワク感を楽しめます！",
      image: "assets/images/home_tutorial3.svg",
    ),
    _TutorialItem(
      title: "聖地に到着してスタンプゲット！",
      description:
          "目的の聖地に到着するとスタンプ獲得！集めたスタンプ数に応じて、周辺店舗で使えるクーポンや限定特典も受け取ることができます！",
      image: "assets/images/home_tutorial4.svg",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            child: SizedBox(
              width: 380,
              height: 720,
              child: Column(
                children: [
                  /// ---------- 青背景 ----------
                  Expanded(
                    flex: 6,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xff2F80ED), Color(0xff2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          /// タイトル
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                            child: Row(
                              children: [
                                const Text(
                                  "アプリ説明",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),

                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    "スキップ",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// ページビュー
                          Expanded(
                            child: PageView.builder(
                              controller: _controller,
                              itemCount: _pages.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPage = index;
                                });
                              },
                              itemBuilder: (_, index) {
                                final page = _pages[index];

                                return Center(
                                  child: SizedBox(
                                    width: 350,
                                    height: 390,
                                    child: SvgPicture.asset(
                                      page.image,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// ---------- 白背景 ----------
                  Expanded(
                    flex: 4,
                    child: Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(34, 24, 34, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _pages[_currentPage].title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _pages[_currentPage].description,
                            style: const TextStyle(fontSize: 16, height: 1.6),
                          ),
                          const Spacer(),

                          /// 最後だけボタン表示
                          if (_currentPage == _pages.length - 1)
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff2563EB),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "はじめる",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.blue
                              : Colors.white,
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// チュートリアルのデータ
class _TutorialItem {
  final String title;
  final String description;
  final String image;

  const _TutorialItem({
    required this.title,
    required this.description,
    required this.image,
  });
}
