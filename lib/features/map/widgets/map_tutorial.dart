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
      title: "聖地を選択",
      description:
          "アニメ作品を検索すると、その作品に関連する聖地が一覧で表示されます。気になる聖地を選択すると、目的地のピンや聖地の詳細情報や現在地からの距離や到着予定時間を確認できます。",
      image: "assets/images/map_tutorial1.svg",
    ),
    _TutorialItem(
      title: "ナビで目的地まで移動",
      description:
          "ナビを開始すると、現在地から目的地までの距離や聖地までのルートが表示されます。現在地もリアルタイムで確認できるため、初めて訪れる場所でも安心して巡礼を楽しめます。",
      image: "assets/images/map_tutorial2.svg",
    ),
    _TutorialItem(
      title: "探索モード",
      description:
          "目的地から約500m圏内に入ると、通常ナビは終了し、方位のみの表示に切り替わります。自分の足で聖地を探し出すワクワク感を楽しめます!",
      image: "assets/images/map_tutorial3.svg",
    ),
    _TutorialItem(
      title: "旅へしゅっぱつ！",
      description: "あなたが選んだ聖地を巡り、作品の世界を体感しよう！",
      image: "assets/images/map_tutorial4.svg",
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
                                  "聖地巡礼の流れ",
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
