import 'package:anitrail/features/shiori/widgets/shiori_complete.dart';
import 'package:flutter/material.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/loading_screen.dart';
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
      final cardId = await _api.createStampCard(
        title: widget.title,
        spotIds: widget.spotIds,
      );
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
      backgroundColor: AppColors.background,
      appBar: const AniTrailAppBar(),
      body: const AppLoadingScreen(message: '旅のしおりを作成しています・・・', imageSize: 300),
    );
  }
}
