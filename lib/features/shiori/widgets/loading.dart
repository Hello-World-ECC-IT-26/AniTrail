import 'dart:async';
import 'package:AniTrail/features/shiori/widgets/shiori_complete.dart';
import 'package:flutter/material.dart';
import '../../../core/widgets/app_bar.dart';

class CreatingShioriScreen extends StatefulWidget {
  const CreatingShioriScreen({super.key});

  @override
  State<CreatingShioriScreen> createState() => _CreatingShioriScreenState();
}

class _CreatingShioriScreenState extends State<CreatingShioriScreen> {
  @override
  void initState() {
    super.initState();
    // 3秒後に自動で次の画面へ遷移する
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ShioriCompleteScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar
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
