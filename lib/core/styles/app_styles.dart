import 'package:flutter/material.dart';

/// アプリ全体で使う色トークン。
/// 画面ごとに色を直書きせず、必ずここを参照する。
class AppColors {
  // ── Primary ───────────────────────────────────────────
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF42A5F5);

  // ── Text ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF555555);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textMuted = Color(0xFF757575);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Background / Surface ──────────────────────────────
  /// 画面の背景（白）。
  static const Color background = Color(0xFFFFFFFF);

  /// カード・シートなどの面。
  static const Color surface = Color(0xFFFFFFFF);

  /// 入力欄やチップの薄いグレー塗り。
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  /// 検索バーなどのごく薄いグレー塗り。
  static const Color surfaceMuted = Color(0xFFF0F0F0);

  /// 画像プレースホルダなどの面。
  static const Color placeholder = Color(0xFFEEEEEE);

  // ── Border / Divider ──────────────────────────────────
  static const Color borderDefault = Color(0xFFCCCCCC);
  static const Color borderLight = Color(0xFFE5E5E5);
  static const Color borderFocused = Color(0xFF1976D2);
  static const Color borderError = Color(0xFFE53935);
  static const Color divider = Color(0xFFE0E0E0);

  // ── Neutral / Icon ────────────────────────────────────
  static const Color iconMuted = Color(0xFF9E9E9E);

  // ── Status ────────────────────────────────────────────
  static const Color error = Color(0xFFE53935);

  /// 通知バッジなどの赤。
  static const Color badge = Color(0xFFE53935);

  // ── Misc ──────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFFDDDDDD);
  static const Color googleBlue = Color(0xFF4285F4);

  // ── Gradient（しおり・検索カードの装飾グラデーション） ──────
  static const Color gradientStart = Color(0xB34A76E8);
  static const Color gradientMid = Color(0x80745FC6);
  static const Color gradientEnd = Color(0x33745FC6);

  /// スタンプ・検索・聖地カードで使う3段グラデーション（左→右）。
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    stops: [0, 0.55, 1],
    colors: [gradientStart, gradientMid, gradientEnd],
  );

  /// しおりカードで使う2段グラデーション（左→右）。
  static const LinearGradient cardGradientSoft = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [gradientStart, gradientEnd],
  );

  /// 旅のしおり作成ボタンの背景色
  static const tabiShiori = Color(0xFF13367C);
}
