import 'package:flutter/material.dart';

class UiSettingsLang {
  static bool ru = true;
}

String tr(String ru, String en) => UiSettingsLang.ru ? ru : en;

class AppTheme {
  final bool isDark;
  final Color bg;
  final Color surface;
  final Color card;
  final Color text;
  final Color accent;
  final Color border;
  final Color buttonColor;
  final Color buttonTextColor;
  final Duration animDur;
  final Curve animCurve;

  const AppTheme({
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.card,
    required this.text,
    required this.accent,
    required this.border,
    required this.buttonColor,
    required this.buttonTextColor,
    this.animDur = const Duration(milliseconds: 280),
    this.animCurve = Curves.easeOutCubic,
  });

  factory AppTheme.dark() => const AppTheme(
        isDark: true,
        bg: Color(0xFF000000),
        surface: Color(0xFF0D0D0F),
        card: Color(0xFF141416),
        text: Color(0xFFF5F6F8),
        accent: Color(0xFF60A5FA),
        border: Color(0x1FFFFFFF),
        buttonColor: Color(0xFF60A5FA),
        buttonTextColor: Color(0xFF0B0E14),
      );

  factory AppTheme.light() => const AppTheme(
        isDark: false,
        bg: Color(0xFFEFF3F9),
        surface: Color(0xFFFBFDFF),
        card: Color(0xFFFFFFFF),
        text: Color(0xFF101418),
        accent: Color(0xFF2563EB),
        border: Color(0x26000000),
        buttonColor: Color(0xFF2563EB),
        buttonTextColor: Color(0xFFFFFFFF),
      );

  AppTheme withAccent(Color c) => AppTheme(
        isDark: isDark, bg: bg, surface: surface, card: card, text: text,
        accent: c, border: border, buttonColor: c,
        buttonTextColor: _readableOn(c),
        animDur: animDur, animCurve: animCurve,
      );

  AppTheme withAnim(Duration d) => AppTheme(
        isDark: isDark, bg: bg, surface: surface, card: card, text: text,
        accent: accent, border: border, buttonColor: buttonColor,
        buttonTextColor: buttonTextColor, animDur: d, animCurve: animCurve,
      );

    AppTheme withButton(Color c) => AppTheme(
        isDark: isDark, bg: bg, surface: surface, card: card, text: text,
        accent: accent, border: border, buttonColor: c,
        buttonTextColor: _readableOn(c), animDur: animDur, animCurve: animCurve,
      );

  static Color _readableOn(Color c) {
    final lum = 0.2126 * c.red + 0.7152 * c.green + 0.0722 * c.blue;
    return lum > 150 ? const Color(0xFF0B0E14) : const Color(0xFFFFFFFF);
  }
}