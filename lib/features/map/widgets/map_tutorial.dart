import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/widgets/app_tutorial_dialog.dart';

const mapTutorialShownKey = 'mapTutorialShown';

Future<bool> showMapTutorialIfNeeded(BuildContext context) async {
  final preferences = await SharedPreferences.getInstance();
  final shown = preferences.getBool(mapTutorialShownKey) ?? false;
  if (shown || !context.mounted) return false;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const TutorialDialog(),
  );
  await preferences.setBool(mapTutorialShownKey, true);
  return true;
}

class TutorialDialog extends StatelessWidget {
  const TutorialDialog({super.key});

  static const _pages = [
    AppTutorialPage(
      title: '聖地を選択',
      description:
          'アニメ作品を検索すると、その作品に関連する聖地が一覧で表示されます。気になる聖地を選択すると、目的地のピンや聖地の詳細情報や現在地からの距離や到着予定時間を確認できます。',
      imageAsset: 'assets/images/map_tutorial1.svg',
    ),
    AppTutorialPage(
      title: 'ナビで目的地まで移動',
      description:
          'ナビを開始すると、現在地から目的地までの距離や聖地までのルートが表示されます。現在地もリアルタイムで確認できるため、初めて訪れる場所でも安心して巡礼を楽しめます。',
      imageAsset: 'assets/images/map_tutorial2.svg',
    ),
    AppTutorialPage(
      title: '探索モード',
      description:
          '目的地から約500m圏内に入ると、通常ナビは終了し、方位のみの表示に切り替わります。自分の足で聖地を探し出すワクワク感を楽しめます!',
      imageAsset: 'assets/images/map_tutorial3.svg',
    ),
    AppTutorialPage(
      title: '旅へしゅっぱつ！',
      description: 'あなたが選んだ聖地を巡り、作品の世界を体感しよう！',
      imageAsset: 'assets/images/map_tutorial4.svg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const AppTutorialDialog(heading: '聖地巡礼の流れ', pages: _pages);
  }
}
