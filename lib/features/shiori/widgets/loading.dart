import 'package:AniTrail/features/shiori/widgets/shiori_complete.dart';
import 'package:flutter/material.dart';
import '../../../core/widgets/app_bar.dart';
import '../../map/models/anime_spot.dart';
import '../../map/services/spot_api.dart';
import '../models/shiori_draft.dart';

class CreatingShioriScreen extends StatefulWidget {
  final String? title;
  final List<Spot> spots;
  final List<String> spotIds;

  const CreatingShioriScreen({
    super.key,
    this.title,
    this.spots = const [],
    this.spotIds = const [],
  });

  @override
  State<CreatingShioriScreen> createState() => _CreatingShioriScreenState();
}

class _CreatingShioriScreenState extends State<CreatingShioriScreen> {
  final SpotApi _api = SpotApi();

  @override
  void initState() {
    super.initState();
    _createShiori();
  }

  Future<void> _createShiori() async {
    try {
      // loading アニメーションを最低2秒見せつつ作成
      final results = await Future.wait([
        _api.createStampCard(title: widget.title, spotIds: widget.spotIds),
        Future.delayed(const Duration(seconds: 2)),
      ]);
      final cardId = results[0] as String?;
      if (!mounted) return;
      if (cardId == null) {
        _showError();
        return;
      }
      ShioriDraft.instance.clear(); // 作成完了したので下書きをリセット
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ShioriCompleteScreen(
            cardId: cardId,
            shioriTitle: widget.title ?? 'しおりタイトル',
            spots: widget.spots,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      debugPrint('Failed to create shiori: $error');
      _showError(error);
    }
  }

  void _showError([Object? error]) {
    final message =
        error?.toString().replaceFirst('Exception: ', '') ?? 'しおりの作成に失敗しました';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AniTrailAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/loading.gif',
              width: 300,
              height: 300,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.directions_walk,
                size: 100,
                color: Colors.black87,
              ),
            ),
            const Text(
              '旅のしおりを作成しています・・・',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
