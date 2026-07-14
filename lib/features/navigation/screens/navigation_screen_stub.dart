import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/styles/app_text.dart';
import '../../map/models/anime_spot.dart';

class NavigationScreen extends StatelessWidget {
  final Spot spot;
  final String cardId;
  final int stampCount;
  final int stampTotal;
  final String? imageUrl;
  final LatLng? origin;

  const NavigationScreen({
    super.key,
    required this.spot,
    required this.cardId,
    this.stampCount = 0,
    this.stampTotal = 0,
    this.imageUrl,
    this.origin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(spot.name)),
      body: const Center(
        child: Text('アプリ内ナビはAndroid/iOSのみ対応です', style: AppTextStyles.body),
      ),
    );
  }
}
