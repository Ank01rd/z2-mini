import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../core/fx_service.dart';
import '../../core/ui_scale.dart';
import '../../core/ui_settings.dart';

class FxOverlay extends StatefulWidget {
  const FxOverlay({super.key});
  @override
  State<FxOverlay> createState() => _FxOverlayState();
}

class _FxOverlayState extends State<FxOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  int _pulseStart = -1;
  int _lastVer = 0;

  @override
  void initState() {
    super.initState();
    FxService.ripples.addListener(_wake);
    FxService.pulseVer.addListener(_onPulse);
    FxService.cursor.addListener(_wake);
  }

  void _wake() {
    if (FxService.ripples.value.isNotEmpty && !_ticker.isActive) {
      _ticker.start();
    }
    setState(() {});
  }

  void _onPulse() {
    if (FxService.pulseVer.value != _lastVer) {
      _lastVer = FxService.pulseVer.value;
      _pulseStart = DateTime.now().millisecondsSinceEpoch;
      if (!_ticker.isActive) _ticker.start();
      setState(() {});
    }
  }

  void _tick(Duration d) {
    final now = DateTime.now().millisecondsSinceEpoch;
    FxService.dropOld(now);
    final pulseDone = _pulseStart < 0 || now - _pulseStart > 1000;
    if (FxService.ripples.value.isEmpty && pulseDone) _ticker.stop();
    setState(() {});
  }

  @override
  void dispose() {
    FxService.ripples.removeListener(_wake);
    FxService.pulseVer.removeListener(_onPulse);
    FxService.cursor.removeListener(_wake);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final accent = UiSettings.accentColor.value ?? const Color(0xFF60A5FA);
    // глобальная точка кнопки → локальные координаты оверлея
    Offset? localOrigin;
    final go = FxService.pulseOrigin;
    if (go != null) {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.attached) {
        localOrigin = box.globalToLocal(go);
      }
    }
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _FxPainter(
          ripples:
              UiSettings.rippleFx.value ? FxService.ripples.value : const [],
          pulseStart: UiSettings.pulseFx.value ? _pulseStart : -1,
          pulseOrigin: localOrigin,
          cursor: UiSettings.cursorGlow.value ? FxService.cursor.value : null,
          now: now,
          accent: accent,
        ),
      ),
    );
  }
}

class _FxPainter extends CustomPainter {
  final List<FxRipple> ripples;
  final int pulseStart;
  final Offset? pulseOrigin;
  final Offset? cursor;
  final int now;
  final Color accent;
  _FxPainter({
    required this.ripples,
    required this.pulseStart,
    required this.now,
    required this.accent,
    this.pulseOrigin,
    this.cursor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ✨ свечение курсора
    if (cursor != null) {
      final r = sc(170);
      canvas.drawCircle(
        cursor!,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              accent.withOpacity(0.16),
              accent.withOpacity(0.06),
              Colors.transparent,
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(Rect.fromCircle(center: cursor!, radius: r)),
      );
    }
    // 💧 ripple по клику
    for (final r in ripples) {
      final age = (now - r.startMs) / 900;
      if (age < 0 || age > 1) continue;
      final rad = 10 + age * 140;
      final a = (1 - age) * 0.35;
      canvas.drawCircle(r.pos, rad,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = accent.withOpacity(a));
      canvas.drawCircle(
          r.pos, rad * 0.7, Paint()..color = accent.withOpacity(a * 0.3));
    }
    // 💫 пульс ИЗ КНОПКИ
    if (pulseStart >= 0) {
      final age = (now - pulseStart) / 1000;
      if (age >= 0 && age <= 1) {
        final c = pulseOrigin ?? Offset(size.width / 2, size.height / 2);
        final rad = 20 + age * math.max(size.width, size.height) * 0.75;
        final a = (1 - age) * 0.30;
        canvas.drawCircle(c, rad,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = accent.withOpacity(a));
        canvas.drawCircle(
            c, rad * 0.96, Paint()..color = accent.withOpacity(a * 0.15));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FxPainter o) => true;
}