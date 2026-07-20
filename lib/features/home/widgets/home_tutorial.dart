import 'package:flutter/material.dart';

import '../../../core/widgets/app_tutorial_dialog.dart';

class TutorialDialog extends StatelessWidget {
  const TutorialDialog({super.key});

  static const _pages = [
    AppTutorialPage(
      title: 'AniTrailへようこそ！',
      description: 'このアプリは、行きたいアニメの聖地を巡りながら、スタンプラリー形式で楽しめる聖地巡礼アプリになっています！',
      imageAsset: 'assets/images/home_tutorial1.svg',
    ),
    AppTutorialPage(
      title: '聖地検索、カード作成',
      description:
          '好きなアニメの聖地を検索して自由に組み合わせ、自分だけの巡礼スタンプカードを作成できます。スタンプを集めながら聖地巡礼を楽しみましょう！',
      imageAsset: 'assets/images/home_tutorial2.svg',
    ),
    AppTutorialPage(
      title: '探索しながら聖地巡礼',
      description:
          'マップでルートや距離を確認しながら移動できます。聖地付近では方位磁石モードに切り替わり、自分の足で聖地を探し出すワクワク感を楽しめます！',
      imageAsset: 'assets/images/home_tutorial3.svg',
    ),
    AppTutorialPage(
      title: '聖地に到着してスタンプゲット！',
      description:
          '目的の聖地に到着するとスタンプ獲得！集めたスタンプ数に応じて、周辺店舗で使えるクーポンや限定特典も受け取ることができます！',
      imageAsset: 'assets/images/home_tutorial4.svg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const AppTutorialDialog(heading: 'アプリ説明', pages: _pages);
  }
}
