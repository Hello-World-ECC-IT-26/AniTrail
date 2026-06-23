import 'package:flutter/material.dart';

/// 影の共通定義。カードやシートで直書きせずこれを使う。
class AppShadows {
  /// カード用のやわらかい影。
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x14000000), // black 8%
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  /// ボトムシートなど、上方向に落ちる影。
  static const List<BoxShadow> sheet = [
    BoxShadow(
      color: Color(0x1F000000), // black 12%
      blurRadius: 8,
    ),
  ];

  /// ちょっとした浮き上がり（小さめ）。
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x0F000000), // black 6%
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];
}
