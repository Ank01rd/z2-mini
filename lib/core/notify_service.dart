import 'dart:async';
import 'package:flutter/material.dart';
import 'sound_service.dart';

class NotifyLine {
  final bool ok;
  final String text;
  const NotifyLine(this.ok, this.text);
}

class NotifyItem {
  final String text;
  final IconData icon;
  final List<NotifyLine>? lines;
  final double? progress; // 0..1 или null
  final VoidCallback? onTap; // ← действие по тапу (например, установка обновы)
  const NotifyItem({
    required this.text,
    required this.icon,
    this.lines,
    this.progress,
    this.onTap,
  });
}

/// 🔔 Островок: одно уведомление. С прогрессом — живёт пока идёт процесс,
/// обычное — 3 сек, результаты — 6 сек, с onTap — 10 сек (юзер должен успеть тапнуть).
class NotifyService {
  static final ValueNotifier<NotifyItem?> banner = ValueNotifier(null);
  static Timer? _timer;

  static void push(
    String text, {
    IconData icon = Icons.notifications_active_rounded,
    List<NotifyLine>? lines,
    bool sound = true,
    double? progress,
    VoidCallback? onTap,
  }) {
    banner.value = NotifyItem(
      text: text,
      icon: icon,
      lines: lines,
      progress: progress,
      onTap: onTap,
    );
    _timer?.cancel();
    if (progress == null) {
      if (sound) {
        Future.delayed(Duration(milliseconds: lines != null ? 250 : 0),
            () => SoundService.notify());
      }
      _timer = Timer(
        Duration(
          milliseconds: onTap != null
              ? 10000
              : (lines != null ? 6000 : 3000),
        ),
        () => banner.value = null,
      );
    }
  }

  static void dismiss() {
    _timer?.cancel();
    banner.value = null;
  }
}