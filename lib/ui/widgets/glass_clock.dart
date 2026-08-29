import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/ui_scale.dart';
import '../../core/ui_settings.dart';

/// 🕐 Компактные стеклянные часы — только время, крупно
class GlassClock extends StatefulWidget {
  const GlassClock({super.key});
  @override
  State<GlassClock> createState() => _GlassClockState();
}

class _GlassClockState extends State<GlassClock> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return ValueListenableBuilder<bool>(
      valueListenable: UiSettings.realBlur,
      builder: (ctx, real, _) {
        final pill = _pill(now);
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (_) => windowManager.startDragging(),
          child: real
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: pill),
                )
              : pill,
        );
      },
    );
  }

  Widget _pill(DateTime now) => Container(
        padding: EdgeInsets.symmetric(horizontal: sc(9), vertical: sc(3)),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Text(
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: sc(10),
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: Colors.white.withOpacity(0.9),
            decoration: TextDecoration.none,
          ),
        ),
      );
}