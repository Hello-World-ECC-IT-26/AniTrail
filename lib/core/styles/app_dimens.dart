import 'package:flutter/material.dart';

/// 余白・角丸・サイズの共通スケール。
/// マジックナンバーを各画面に直書きせず、ここを参照して統一感を出す。
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

/// 角丸の共通スケール。混在していた 6/8/10/12/16 を 8/12/16 に統一する。
class AppRadius {
  /// ボタン・サムネイル・小さめの面（8）。
  static const double sm = 8;

  /// 入力欄・スナックバー・中くらいの面（12）。
  static const double md = 12;

  /// カード・シート・ダイアログ（16）。
  static const double lg = 16;

  /// チップ・ピル（完全な丸み）。
  static const double pill = 999;

  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
}

/// 主要なUIサイズ。
class AppSizes {
  /// 標準ボタン高さ。
  static const double buttonHeight = 48;

  /// アイコンボタンなどの最小タップ領域。
  static const double minTapTarget = 44;
}
