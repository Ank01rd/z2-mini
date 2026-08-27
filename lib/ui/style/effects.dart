import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../core/ui_settings.dart';

/// 🎨 Общий helper: детерминированный «рандом» из seed для стабильной сцены
double _jit(int i, double salt) {
  final x = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return x - x.floor();
}

/// 🍃 дешёвое мягкое пятно: радиальный градиент вместо MaskFilter.blur
Paint _soft(Color c, double r, Offset at) => Paint()
  ..shader = ui.Gradient.radial(at, r,
      [c, c.withOpacity(0.55), c.withOpacity(0)], [0.0, 0.45, 1.0]);

/// 📦 кэш TextPainter: layout один раз — рисуем вечно
final Map<int, TextPainter> _tpCache = {};
TextPainter _cachedTp(String text, Color color, double size,
    {FontWeight? weight}) {
  final key = Object.hash(text, color.value, size, weight?.index ?? -1);
  var tp = _tpCache[key];
  if (tp == null) {
    tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color,
              fontSize: size,
              fontFamily: 'Consolas',
              fontWeight: weight)),
      textDirection: TextDirection.ltr,
    )..layout();
    if (_tpCache.length > 500) _tpCache.clear();
    _tpCache[key] = tp;
  }
  return tp;
}

/// Живой фон с 47 стилями
class LiveBackground extends StatefulWidget {
  final Color color;
  final double speed;
  final int style;
  final double density;
  const LiveBackground({
    super.key,
    required this.color,
    required this.speed,
    required this.style,
    this.density = 1.0,
  });
  @override
  State<LiveBackground> createState() => _LiveBackgroundState();
}

class _LiveBackgroundState extends State<LiveBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  double _t = 0;
  int _lastMs = -1;

  int get _fps =>
      UiSettings.ecoMode.value ? 12 : UiSettings.fpsCap.value.clamp(12, 60);

  void _onTick(Duration elapsed) {
    final ms = elapsed.inMilliseconds;
    if (_lastMs < 0) {
      _lastMs = ms;
      return;
    }
    final dt = ms - _lastMs;
    final interval = 1000 ~/ _fps;
    if (dt < interval) return; // лишние кадры пропускаем → GPU отдыхает
    _lastMs = ms;
    // время идёт реальными дельтами (кап 100мс — без скачков после паузы)
    _t += (dt / 1000.0).clamp(0.0, 0.1) * widget.speed * 0.25;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _ticker.start();
    UiSettings.windowFocused.addListener(_onFocus);
  }

  @override
  void dispose() {
    UiSettings.windowFocused.removeListener(_onFocus);
    _ticker.dispose();
    super.dispose();
  }

  // 💤 AFK: тикер стоит (0% GPU); при фокусе — сброс _lastMs и мгновенный кадр
  void _onFocus() {
    if (UiSettings.windowFocused.value) {
      if (!_ticker.isActive) {
        _lastMs = -1;
        _ticker.start();
      }
    } else {
      if (_ticker.isActive) _ticker.stop();
    }
  }

  @override
  Widget build(BuildContext context) =>
      RepaintBoundary(child: _scene(_t));

  Widget _scene(double t) {
    switch (widget.style) {
          case 0:
            return CustomPaint(
                painter: _AuroraPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 1:
            return CustomPaint(
                painter: _WavesPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 2:
            return CustomPaint(
                painter: _StarsPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 3:
            return CustomPaint(
                painter: _MyWavePainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 4:
            return CustomPaint(
                painter: _CloudsPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 5:
            return CustomPaint(
                painter: _DucksPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 6:
            return CustomPaint(
                painter: _FrogsPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 7:
            return CustomPaint(
                painter: _DotsPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 8:
            return CustomPaint(
                painter: _AquariumPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 9:
            return CustomPaint(
                painter: _NebulaPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 10:
            return CustomPaint(
                painter: _BlackHolePainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 11:
            return CustomPaint(
                painter: _CometPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 12:
            return CustomPaint(
                painter: _MeteorPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 13:
            return CustomPaint(
                painter: _OrbitsPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 14:
            return CustomPaint(
                painter: _MoonPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 15:
            return CustomPaint(
                painter: _StarDustPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 16:
            return CustomPaint(
                painter: _FirefliesPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 17:
            return CustomPaint(
                painter: _LeavesPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 18:
            return CustomPaint(
                painter: _SakuraPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 19:
            return CustomPaint(
                painter: _SnowPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 20:
            return CustomPaint(
                painter: _RainPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 21:
            return CustomPaint(
                painter: _RainDropsPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 22:
            return CustomPaint(
                painter: _SmokePainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 23:
            return CustomPaint(
                painter: _DustLightPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 24:
            return CustomPaint(
                painter: _LavaLampPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 25:
            return CustomPaint(
                painter: _MatrixPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 26:
            return CustomPaint(
                painter: _SynthwavePainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 27:
            return CustomPaint(
                painter: _CrtPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 28:
            return CustomPaint(
                painter: _TerminalPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 29:
            return CustomPaint(
                painter: _RadarPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 30:
            return CustomPaint(
                painter: _OscPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 31:
            return CustomPaint(
                painter: _VhsPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 32:
            return CustomPaint(
                painter: _PixelCloudsPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 33:
            return CustomPaint(
                painter: _RibbonsPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 34:
            return CustomPaint(
                painter: _KaleidoPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 35:
            return CustomPaint(
                painter: _MandalaPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 36:
            return CustomPaint(
                painter: _TopoPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 37:
            return CustomPaint(
                painter: _HexPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 38:
            return CustomPaint(
                painter: _PulsarPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 39:
            return CustomPaint(
                painter: _VoronoiPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 40:
            return CustomPaint(
                painter: _BubblesPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 41:
            return CustomPaint(
                painter: _NightCityPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 42:
            return CustomPaint(
                painter: _NeonPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 43:
            return CustomPaint(
                painter: _FireplacePainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 44:
            return CustomPaint(
                painter: _VinylPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 45:
            return CustomPaint(
                painter: _ConfettiPainter(t, widget.color, widget.density),
                size: Size.infinite);
          case 46:
            return CustomPaint(
                painter: _PlanesPainter(t, widget.color, widget.density),
                size: Size.infinite);
          default:
            return const SizedBox.shrink();
        }
      }
    }

// ═══════════════════════════════════════════════════════════
// БАЗА (старые 9)
// ═══════════════════════════════════════════════════════════

class _AuroraPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _AuroraPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()..blendMode = ui.BlendMode.plus;
    for (var i = 0; i < 4; i++) {
      final path = Path();
      final yBase = h * (0.35 + 0.05 * i);
      path.moveTo(-50, yBase);
      for (double x = -50; x <= w + 50; x += 30) {
        final y = yBase +
            math.sin(x * 0.005 + t * 2 + i) * 60 * d +
            math.sin(x * 0.012 - t * 1.5 + i * 2) * 30;
        path.lineTo(x, y);
      }
      path.lineTo(w + 50, h + 50);
      path.lineTo(-50, h + 50);
      path.close();
      p.shader = ui.Gradient.linear(
          Offset(0, yBase - 80), Offset(0, h),
          [base.withOpacity(0.25), base.withOpacity(0.05), Colors.transparent]);
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter o) => o.t != t;
}

class _WavesPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _WavesPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    for (var i = 0; i < 5; i++) {
      final path = Path();
      final yBase = h * (0.55 + 0.08 * i);
      path.moveTo(0, yBase);
      for (double x = 0; x <= w; x += 10) {
        final y = yBase +
            math.sin(x * 0.008 + t * (1.5 + i * 0.2)) * 30 * d +
            math.cos(x * 0.015 - t + i) * 15;
        path.lineTo(x, y);
      }
      path.lineTo(w, h);
      path.lineTo(0, h);
      path.close();
      canvas.drawPath(
          path, Paint()..color = base.withOpacity(0.10 - 0.015 * i));
    }
  }

  @override
  bool shouldRepaint(covariant _WavesPainter o) => o.t != t;
}

class _StarsPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _StarsPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = (60 * d).round().clamp(20, 200);
    for (var i = 0; i < n; i++) {
      final x = _jit(i, 0.13) * w;
      final y = _jit(i, 0.71) * h;
      final r = 0.6 + _jit(i, 0.31) * 1.8;
      final ph = _jit(i, 0.57);
      final twinkle = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(t * 4 + ph * 10));
      canvas.drawCircle(
          Offset(x, y),
          r,
          Paint()..color = base.withOpacity(twinkle));
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter o) => o.t != t;
}

class _MyWavePainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _MyWavePainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()
      ..shader = ui.Gradient.linear(
          Offset(0, 0), Offset(w, h),
          [base.withOpacity(0.4), base.withOpacity(0.1)]);
    final path = Path();
    path.moveTo(0, h / 2);
    for (double x = 0; x <= w; x += 8) {
      final y = h / 2 +
          math.sin(x * 0.01 + t * 2) * 40 * d +
          math.cos(x * 0.025 - t * 1.3) * 20;
      path.lineTo(x, y);
    }
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _MyWavePainter o) => o.t != t;
}

class _CloudsPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _CloudsPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = (10 * d).round().clamp(4, 20);
    for (var i = 0; i < n; i++) {
      final speed = 0.1 + _jit(i, 0.3) * 0.3;
      var x = ((_jit(i, 0.7) * w + t * speed * 60) % (w + 300)) - 150;
      final y = _jit(i, 0.9) * h * 0.8 + h * 0.1;
      final r = 60 + _jit(i, 0.5) * 80;
      final c = base.withOpacity(0.10 + 0.04 * _jit(i, 0.2));
      final R = r * 1.8;
      canvas.drawCircle(Offset(x, y), R, _soft(c, R, Offset(x, y)));
      canvas.drawCircle(Offset(x + r * 0.5, y - r * 0.2), R * 0.8,
          _soft(c, R * 0.8, Offset(x + r * 0.5, y - r * 0.2)));
      canvas.drawCircle(Offset(x - r * 0.5, y + r * 0.1), R * 0.7,
          _soft(c, R * 0.7, Offset(x - r * 0.5, y + r * 0.1)));
    }
  }

  @override
  bool shouldRepaint(covariant _CloudsPainter o) => o.t != t;
}

class _DucksPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _DucksPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = (6 * d).round().clamp(2, 12);
    for (var i = 0; i < n; i++) {
      final speed = 0.3 + _jit(i, 0.3) * 0.5;
      var x = ((_jit(i, 0.7) * w + t * speed * 80) % (w + 200)) - 100;
      final y = _jit(i, 0.9) * h * 0.7 + h * 0.15;
      final scale = 0.8 + _jit(i, 0.5) * 0.5;
      canvas.save();
      canvas.translate(x, y);
      canvas.scale(scale, scale);
      final p = Paint()..color = base.withOpacity(0.8);
      // тело
      canvas.drawOval(Rect.fromLTWH(-18, -6, 36, 18), p);
      // голова
      canvas.drawCircle(const Offset(20, -8), 9, p);
      // клюв
      canvas.drawOval(Rect.fromLTWH(26, -9, 8, 4),
          Paint()..color = const Color(0xFFFFA500));
      // глаз
      canvas.drawCircle(const Offset(22, -10), 1.5,
          Paint()..color = Colors.black);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _DucksPainter o) => o.t != t;
}

class _FrogsPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _FrogsPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = (5 * d).round().clamp(2, 10);
    for (var i = 0; i < n; i++) {
      var x = _jit(i, 0.7) * w;
      final y = _jit(i, 0.9) * h * 0.7 + h * 0.15;
      final scale = 0.7 + _jit(i, 0.5) * 0.5;
      final hop = math.sin(t * 2 + i).abs() * 10;
      canvas.save();
      canvas.translate(x, y - hop);
      canvas.scale(scale, scale);
      final g = const Color(0xFF22C55E);
      final p = Paint()..color = g;
      canvas.drawOval(Rect.fromLTWH(-16, -8, 32, 20), p);
      canvas.drawCircle(const Offset(-8, -14), 6, p);
      canvas.drawCircle(const Offset(8, -14), 6, p);
      canvas.drawCircle(const Offset(-8, -14), 2, Paint()..color = Colors.black);
      canvas.drawCircle(const Offset(8, -14), 2, Paint()..color = Colors.black);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FrogsPainter o) => o.t != t;
}

class _DotsPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _DotsPainter(this.t, this.base, this.d);
  static const double _tau = 2 * math.pi;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final tint = Color.lerp(base, Colors.white, 0.5)!;
    final step = (16 / d).clamp(10.0, 28.0);
    final p = Paint();
    for (double y = step / 2; y < h; y += step) {
      for (double x = step / 2; x < w; x += step) {
        final v = math.sin((x + y) * 0.02 + _tau * t) *
            math.cos(x * 0.008 - _tau * t * 0.5);
        final k = 0.5 + 0.5 * v;
        p.color = tint.withOpacity(0.04 + 0.16 * k);
        canvas.drawCircle(Offset(x, y), 0.7 + 0.9 * k, p);
      }
    }
    final lp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = tint.withOpacity(0.22);
    final n = (7 * d).round().clamp(3, 14);
    for (var l = 0; l < n; l++) {
      final off = l * (w + h) / n;
      final path = Path();
      for (double dx = -h; dx <= w + h; dx += 12) {
        final x = dx;
        final y = -dx * 0.9 + off + math.sin(dx * 0.01 + _tau * t + l * 1.7) * 14;
        if (dx <= -h) path.moveTo(x, y);
        else path.lineTo(x, y);
      }
      canvas.drawPath(path, lp);
    }
    for (var k = 0; k < 2; k++) {
      final c = k == 0 ? const Offset(0.95, 0.05) : const Offset(0.05, 0.95);
      final ph = k * 2.3;
      final cx = c.dx * w + math.sin(_tau * t * 0.4 + ph) * w * 0.012;
      final cy = c.dy * h + math.cos(_tau * t * 0.33 + ph) * h * 0.012;
      final r = math.max(w, h) * 0.35 * (0.92 + 0.08 * math.sin(_tau * t * 0.6 + ph));
      canvas.drawRect(
        Rect.fromLTRB(cx - r, cy - r, cx + r, cy + r),
        Paint()
          ..shader = ui.Gradient.radial(Offset(cx, cy), r, [
            Colors.black.withOpacity(0.40 + 0.10 * math.sin(_tau * t * 0.5 + ph)),
            Colors.black.withOpacity(0.0),
          ]),
      );
      final rp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 0.7
        ..color = tint.withOpacity(0.18);
      for (var i = 0; i < 24; i++) {
        final a = i / 24 * _tau + math.sin(_tau * t * 0.5 + i * 1.7 + ph) * 0.10;
        final len = 0.45 + 0.40 * (0.5 + 0.5 * math.sin(_tau * t * 0.8 + i * 0.9 + ph));
        canvas.drawLine(
          Offset(cx + math.cos(a) * r * 0.10, cy + math.sin(a) * r * 0.10),
          Offset(cx + math.cos(a) * r * len, cy + math.sin(a) * r * len),
          rp,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter o) => o.t != t;
}

class _AquariumPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _AquariumPainter(this.t, this.base, this.d);
  static const double _tau = 2 * math.pi;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final tint = Color.lerp(base, Colors.white, 0.55)!;
    canvas.drawRect(
      Rect.fromLTRB(0, 0, w, h),
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, h), [
          base.withOpacity(0.16),
          base.withOpacity(0.06),
          Colors.black.withOpacity(0.25),
        ], [0.0, 0.5, 1.0]),
    );
    final rnd = math.Random(97531);
    final n = (18 * d).round().clamp(4, 70);
    for (var i = 0; i < n; i++) {
      final bx = rnd.nextDouble();
      final speed = 0.22 + rnd.nextDouble() * 0.55;
      final r = 1.5 + rnd.nextDouble() * 4.5;
      final ph = rnd.nextDouble();
      final drift = 6.0 + rnd.nextDouble() * 16.0;
      final life = (t * speed + ph) % 1.0;
      final y = h + 20 - life * (h + 40);
      final x = bx * w + math.sin(_tau * (t * 0.5 + ph) * 2) * drift;
      final fade = life < 0.1 ? life / 0.1 : (life > 0.9 ? (1 - life) / 0.1 : 1.0);
      canvas.drawCircle(
          Offset(x, y),
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0
            ..color = tint.withOpacity(0.35 * fade));
      canvas.drawCircle(Offset(x - r * 0.35, y - r * 0.35), r * 0.25,
          Paint()..color = tint.withOpacity(0.5 * fade));
    }
  }

  @override
  bool shouldRepaint(covariant _AquariumPainter o) => o.t != t;
}

// ═══════════════════════════════════════════════════════════
// 🌌 КОСМОС (9-15)
// ═══════════════════════════════════════════════════════════

class _NebulaPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _NebulaPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = (12 * d).round().clamp(6, 20);
    final p = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    for (var i = 0; i < n; i++) {
      final phase = _jit(i, 0.13) * 6.28;
      final x = w * (_jit(i, 0.37) + math.sin(t * 0.3 + phase) * 0.08);
      final y = h * (_jit(i, 0.57) + math.cos(t * 0.25 + phase) * 0.08);
      final r = 80 + _jit(i, 0.9) * 120;
      final hueShift = _jit(i, 0.22) * 60 - 30;
      final hsv = HSVColor.fromColor(base);
      final c = hsv.withHue((hsv.hue + hueShift) % 360).toColor().withOpacity(0.18);
      p.color = c;
      canvas.drawCircle(Offset(x, y), r, p);
    }
  }

  @override
  bool shouldRepaint(covariant _NebulaPainter o) => o.t != t;
}

class _BlackHolePainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _BlackHolePainter(this.t, this.base, this.d);
  static const _tau = 2 * math.pi;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;
    final rMax = math.min(w, h) * 0.45;
    // аккреционный диск
    final p = Paint()..blendMode = ui.BlendMode.plus;
    for (var ring = 0; ring < 30; ring++) {
      final r = rMax * (0.4 + ring / 30 * 0.6);
      final alpha = (1 - ring / 30) * 0.18;
      p.color = base.withOpacity(alpha);
      p.style = PaintingStyle.stroke;
      p.strokeWidth = 2;
      canvas.drawOval(
          Rect.fromCircle(center: Offset(cx, cy), radius: r), p);
    }
    // частицы по спирали
    final n = (80 * d).round().clamp(30, 150);
    for (var i = 0; i < n; i++) {
      final ph = _jit(i, 0.11) * _tau;
      final spd = 0.5 + _jit(i, 0.31) * 1.5;
      final life = (t * spd + _jit(i, 0.7)) % 1.0;
      final angle = ph + life * 8;
      final r = rMax * (1 - life) * 0.95;
      final x = cx + math.cos(angle) * r;
      final y = cy + math.sin(angle) * r * 0.3;
      final sz = 0.6 + _jit(i, 0.5) * 1.2;
      canvas.drawCircle(Offset(x, y), sz,
          Paint()..color = base.withOpacity((1 - life) * 0.9));
    }
    // чёрная дыра
    canvas.drawCircle(
        Offset(cx, cy),
        rMax * 0.35,
        Paint()..color = Colors.black);
    canvas.drawCircle(
        Offset(cx, cy),
        rMax * 0.38,
        Paint()
          ..shader = ui.Gradient.radial(Offset(cx, cy), rMax * 0.38,
              [base.withOpacity(0.4), Colors.black]));
  }

  @override
  bool shouldRepaint(covariant _BlackHolePainter o) => o.t != t;
}

class _CometPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _CometPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = (3 * d).round().clamp(1, 6);
    for (var i = 0; i < n; i++) {
      final spd = 0.3 + _jit(i, 0.3) * 0.5;
      final ph = _jit(i, 0.7);
      final life = (t * spd + ph) % 1.0;
      final x = -100 + life * (w + 200);
      final y = _jit(i, 0.5) * h * 0.7 + h * 0.15;
      // хвост
      final path = Path()
        ..moveTo(x, y)
        ..lineTo(x - 200, y + 40);
      canvas.drawPath(
          path,
          Paint()
            ..shader = ui.Gradient.linear(Offset(x, y), Offset(x - 200, y + 40),
                [base.withOpacity(0.35), Colors.transparent])
            ..strokeWidth = 7
            ..style = PaintingStyle.stroke);
      canvas.drawPath(
          path,
          Paint()
            ..shader = ui.Gradient.linear(Offset(x, y), Offset(x - 200, y + 40),
                [base.withOpacity(0.8), Colors.transparent])
            ..strokeWidth = 2.5
            ..style = PaintingStyle.stroke);
      // голова
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = Colors.white);
      // искры в хвосте
      for (var k = 0; k < 12; k++) {
        final kx = x - k * 16 - _jit(i + k, 0.1) * 10;
        final ky = y + k * 3 + _jit(i + k, 0.3) * 20 - 10;
        canvas.drawCircle(
            Offset(kx, ky),
            0.5 + _jit(i + k, 0.5) * 1.5,
            Paint()..color = base.withOpacity(1 - k / 12));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CometPainter o) => o.t != t;
}

class _MeteorPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _MeteorPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = (15 * d).round().clamp(5, 40);
    for (var i = 0; i < n; i++) {
      final spd = 0.8 + _jit(i, 0.3) * 1.2;
      final ph = _jit(i, 0.7);
      final life = (t * spd + ph) % 1.0;
      final x0 = _jit(i, 0.9) * w * 1.5;
      final y0 = -50;
      final x = x0 - life * 200;
      final y = y0 + life * (h + 100);
      final fade = life < 0.1 ? life / 0.1 : (life > 0.8 ? (1 - life) / 0.2 : 1.0);
      final path = Path()
        ..moveTo(x, y)
        ..lineTo(x + 80, y - 120);
      canvas.drawPath(
          path,
          Paint()
            ..shader = ui.Gradient.linear(Offset(x, y), Offset(x + 80, y - 120),
                [base.withOpacity(0.8 * fade), Colors.transparent])
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _MeteorPainter o) => o.t != t;
}

class _OrbitsPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _OrbitsPainter(this.t, this.base, this.d);
  static const _tau = 2 * math.pi;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = base.withOpacity(0.15);
    final n = (5 * d).round().clamp(3, 8);
    for (var i = 0; i < n; i++) {
      final r = 40 + i * 30;
      canvas.drawCircle(Offset(cx, cy), r.toDouble(), p);
      final spd = 0.5 / (1 + i * 0.3);
      final angle = t * spd + i * 1.3;
      final x = cx + math.cos(angle) * r;
      final y = cy + math.sin(angle) * r;
      final sz = 3 + (n - i).toDouble();
      // трейл
      for (var k = 0; k < 20; k++) {
        final ta = angle - k * 0.05;
        final tx = cx + math.cos(ta) * r;
        final ty = cy + math.sin(ta) * r;
        canvas.drawCircle(
            Offset(tx, ty),
            sz * (1 - k / 20),
            Paint()..color = base.withOpacity((1 - k / 20) * 0.5));
      }
      canvas.drawCircle(Offset(x, y), sz, Paint()..color = base);
    }
    canvas.drawCircle(Offset(cx, cy), 6, Paint()..color = base);
  }

  @override
  bool shouldRepaint(covariant _OrbitsPainter o) => o.t != t;
}

class _MoonPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _MoonPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = math.min(w, h) * 0.12;
    final mx = w * 0.75, my = h * 0.25;
    // луна
    canvas.drawCircle(
        Offset(mx, my),
        r,
        Paint()..color = const Color(0xFFF5F5DC).withOpacity(0.9));
    canvas.drawCircle(
        Offset(mx, my),
        r,
        Paint()
          ..shader = ui.Gradient.radial(
              Offset(mx, my), r * 1.5,
              [Colors.white.withOpacity(0.3), Colors.transparent]));
    // облака
    final n = (8 * d).round().clamp(4, 14);
    final c = base.withOpacity(0.25);
    for (var i = 0; i < n; i++) {
      final spd = 0.1 + _jit(i, 0.3) * 0.2;
      final x = ((_jit(i, 0.7) * w * 2 + t * spd * 80) % (w + 400)) - 200;
      final y = _jit(i, 0.5) * h * 0.6 + h * 0.2;
      final rr = (40 + _jit(i, 0.9) * 60) * 1.7;
      canvas.drawCircle(Offset(x, y), rr, _soft(c, rr, Offset(x, y)));
      canvas.drawCircle(Offset(x + rr * 0.6, y), rr * 0.7,
          _soft(c, rr * 0.7, Offset(x + rr * 0.6, y)));
    }
  }

  @override
  bool shouldRepaint(covariant _MoonPainter o) => o.t != t;
}

class _StarDustPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _StarDustPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = (200 * d).round().clamp(60, 400);
    for (var i = 0; i < n; i++) {
      final layer = _jit(i, 0.11) * 3; // параллакс слои
      final spd = 0.05 + layer * 0.08;
      var x = ((_jit(i, 0.31) * w + t * spd * 40) % w);
      final y = _jit(i, 0.71) * h;
      final r = 0.3 + layer * 0.4;
      final twinkle = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(t * 3 + i * 0.7));
      canvas.drawCircle(Offset(x, y), r,
          Paint()..color = base.withOpacity(twinkle * (0.3 + layer / 3)));
    }
  }

  @override
  bool shouldRepaint(covariant _StarDustPainter o) => o.t != t;
}

// ═══════════════════════════════════════════════════════════
// 🌿 ПРИРОДА (16-24)
// ═══════════════════════════════════════════════════════════

class _FirefliesPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _FirefliesPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = (30 * d).round().clamp(10, 80);
    for (var i = 0; i < n; i++) {
      final ph = _jit(i, 0.3) * 6.28;
      final bx = _jit(i, 0.7) * w;
      final by = _jit(i, 0.5) * h;
      final x = bx + math.sin(t * 0.7 + ph) * 40;
      final y = by + math.cos(t * 0.5 + ph * 1.3) * 30;
      final pulse = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(t * 4 + ph));
      // ореол
      canvas.drawCircle(Offset(x, y), 16,
          _soft(base.withOpacity(pulse * 0.5), 16, Offset(x, y)));
      canvas.drawCircle(Offset(x, y), 1.5,
          Paint()..color = base.withOpacity(pulse));
    }
  }

  @override
  bool shouldRepaint(covariant _FirefliesPainter o) => o.t != t;
}

class _LeavesPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _LeavesPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = (20 * d).round().clamp(8, 40);
    for (var i = 0; i < n; i++) {
      final spd = 0.2 + _jit(i, 0.3) * 0.4;
      final ph = _jit(i, 0.7);
      final life = (t * spd + ph) % 1.0;
      final y = -20 + life * (h + 40);
      final x = _jit(i, 0.9) * w + math.sin(t * 2 + ph * 3) * 40;
      final rot = t * 2 + ph * 6;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      canvas.drawOval(
          Rect.fromLTWH(-6, -3, 12, 6),
          Paint()..color = base.withOpacity(0.7));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LeavesPainter o) => o.t != t;
}

class _SakuraPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _SakuraPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final pink = const Color(0xFFFFB7C5);
    final n = (25 * d).round().clamp(8, 50);
    for (var i = 0; i < n; i++) {
      final spd = 0.15 + _jit(i, 0.3) * 0.3;
      final ph = _jit(i, 0.7);
      final life = (t * spd + ph) % 1.0;
      final y = -20 + life * (h + 40);
      final x = _jit(i, 0.9) * w + math.sin(t * 1.5 + ph * 4) * 30;
      final rot = t + ph * 5;
      final sz = 3 + _jit(i, 0.2) * 3;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      for (var k = 0; k < 5; k++) {
        canvas.save();
        canvas.rotate(k * 6.28 / 5);
        canvas.drawOval(
            Rect.fromLTWH(-sz * 0.4, -sz, sz * 0.8, sz),
            Paint()..color = pink.withOpacity(0.7));
        canvas.restore();
      }
      canvas.drawCircle(Offset.zero, sz * 0.3,
          Paint()..color = base.withOpacity(0.8));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SakuraPainter o) => o.t != t;
}

class _SnowPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _SnowPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = (60 * d).round().clamp(20, 150);
    for (var i = 0; i < n; i++) {
      final spd = 0.15 + _jit(i, 0.3) * 0.4;
      final ph = _jit(i, 0.7);
      final life = (t * spd + ph) % 1.0;
      final y = -20 + life * (h + 40);
      final wind = math.sin(t * 0.7) * 20;
      final x = _jit(i, 0.9) * w + wind + math.sin(t * 2 + ph * 3) * 10;
      final r = 0.8 + _jit(i, 0.2) * 1.5;
      canvas.drawCircle(Offset(x, y), r,
          Paint()..color = Colors.white.withOpacity(0.7));
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter o) => o.t != t;
}

class _RainPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _RainPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = (80 * d).round().clamp(30, 200);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = base.withOpacity(0.4);
    for (var i = 0; i < n; i++) {
      final spd = 0.8 + _jit(i, 0.3) * 1.2;
      final ph = _jit(i, 0.7);
      final life = (t * spd + ph) % 1.0;
      final y = -20 + life * (h + 40);
      final x = _jit(i, 0.9) * w;
      canvas.drawLine(Offset(x, y), Offset(x - 3, y + 15), p);
    }
    // круги от дождя
    for (var i = 0; i < n ~/ 2; i++) {
      final spd = 0.5 + _jit(i, 0.2) * 0.5;
      final ph = _jit(i, 0.5);
      final life = (t * spd + ph) % 1.0;
      final x = _jit(i, 0.1) * w;
      final y = _jit(i, 0.3) * h;
      final r = life * 20;
      canvas.drawCircle(
          Offset(x, y),
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8
            ..color = base.withOpacity((1 - life) * 0.5));
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter o) => o.t != t;
}

class _RainDropsPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _RainDropsPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = (40 * d).round().clamp(15, 80);
    for (var i = 0; i < n; i++) {
      final spd = 0.1 + _jit(i, 0.3) * 0.3;
      final x = _jit(i, 0.7) * w;
      var y = (_jit(i, 0.9) * h + t * spd * 100) % h;
      final path = Path();
      path.moveTo(x, y);
      for (var k = 0; k < 30; k++) {
        y += 4;
        final dx = math.sin((y + i) * 0.1) * 2;
        path.lineTo(x + dx, y);
        if (y > h) break;
      }
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = base.withOpacity(0.4));
      canvas.drawCircle(Offset(x, y), 3,
          Paint()..color = base.withOpacity(0.6));
    }
  }

  @override
  bool shouldRepaint(covariant _RainDropsPainter o) => o.t != t;
}

class _SmokePainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _SmokePainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = (15 * d).round().clamp(6, 25);
    for (var i = 0; i < n; i++) {
      final spd = 0.08 + _jit(i, 0.3) * 0.15;
      final ph = _jit(i, 0.7);
      final life = (t * spd + ph) % 1.0;
      final x = _jit(i, 0.9) * w + math.sin(t * 0.3 + i) * 30;
      final y = h - life * h * 1.2;
      final r = 60 + life * 100;
      final alpha = (1 - life) * 0.15;
      final R = r * 1.5;
      canvas.drawCircle(
          Offset(x, y), R, _soft(base.withOpacity(alpha), R, Offset(x, y)));
    }
  }

  @override
  bool shouldRepaint(covariant _SmokePainter o) => o.t != t;
}

class _DustLightPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _DustLightPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // луч
    final path = Path()
      ..moveTo(w * 0.3, -50)
      ..lineTo(w * 0.6, h + 50)
      ..lineTo(w * 0.8, h + 50)
      ..lineTo(w * 0.5, -50)
      ..close();
    canvas.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(Offset(w * 0.4, 0), Offset(w * 0.6, h),
              [base.withOpacity(0.15), Colors.transparent]));
    // пылинки в луче
    final n = (100 * d).round().clamp(30, 250);
    for (var i = 0; i < n; i++) {
      final ph = _jit(i, 0.3) * 6.28;
      final baseX = _jit(i, 0.7) * w * 0.4 + w * 0.3;
      final baseY = _jit(i, 0.9) * h;
      final x = baseX + math.sin(t * 0.5 + ph) * 20;
      final y = baseY + math.cos(t * 0.3 + ph) * 15;
      final r = 0.5 + _jit(i, 0.2) * 1;
      final tw = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(t * 2 + i));
      canvas.drawCircle(Offset(x, y), r,
          Paint()..color = base.withOpacity(tw));
    }
  }

  @override
  bool shouldRepaint(covariant _DustLightPainter o) => o.t != t;
}

class _LavaLampPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _LavaLampPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = (8 * d).round().clamp(4, 14);
    for (var i = 0; i < n; i++) {
      final spd = 0.3 + _jit(i, 0.3) * 0.4;
      final ph = _jit(i, 0.7);
      final life = (t * spd + ph) % 1.0;
      final x = _jit(i, 0.9) * w;
      final y = h - life * h * 1.3 + 50;
      final r = 40 + math.sin(t + i) * 20;
      final c = base.withOpacity(0.6);
      final R = r * 1.6;
      canvas.drawCircle(Offset(x, y), R, _soft(c, R, Offset(x, y)));
      canvas.drawCircle(Offset(x + r * 0.3, y + r * 0.3), R * 0.7,
          _soft(c, R * 0.7, Offset(x + r * 0.3, y + r * 0.3)));
    }
  }

  @override
  bool shouldRepaint(covariant _LavaLampPainter o) => o.t != t;
}

// ═══════════════════════════════════════════════════════════
// 🕹 РЕТРО/ТЕХНО (25-32)
// ═══════════════════════════════════════════════════════════

class _MatrixPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _MatrixPainter(this.t, this.base, this.d);
  static const glyphs = 'アイウエオカキクケコサシスセソタチツテトナニヌネノ0123456789ABCDEF';
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cols = (w / 16 * d).round().clamp(10, 80);
    final cellW = w / cols;
    for (var i = 0; i < cols; i++) {
      final spd = 0.3 + _jit(i, 0.3) * 0.7;
      final ph = _jit(i, 0.7);
      final y0 = (t * spd * h + ph * h) % (h + 200) - 100;
      final len = 10 + (_jit(i, 0.9) * 15).round();
      for (var k = 0; k < len; k++) {
        final y = y0 - k * 16;
        if (y < -16 || y > h + 16) continue;
        final ch = glyphs[(t * 10 + i * 13 + k * 7).floor() % glyphs.length];
        final alpha = k == 0 ? 1.0 : (1 - k / len) * 0.6;
        final aB = (alpha * 5).round() / 5;
        _cachedTp(ch, base.withOpacity(aB), 14)
            .paint(canvas, Offset(i * cellW, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MatrixPainter o) => o.t != t;
}

class _SynthwavePainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _SynthwavePainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final horizon = h * 0.55;
    // полосатое солнце
    for (var i = 0; i < 8; i++) {
      final y = horizon - 80 + i * 10;
      canvas.drawRect(
          Rect.fromLTWH(w / 2 - 60, y, 120, 5),
          Paint()..color = base.withOpacity(0.4 - i * 0.04));
    }
    canvas.drawCircle(
        Offset(w / 2, horizon - 40),
        60,
        Paint()
          ..shader = ui.Gradient.linear(
              Offset(w / 2, horizon - 100), Offset(w / 2, horizon),
              [base.withOpacity(0.8), base.withOpacity(0.3)]));
    // сетка
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = base.withOpacity(0.5);
    // горизонтали
    for (var i = 0; i < 20; i++) {
      final y = horizon + i * i * 2;
      if (y > h) break;
      canvas.drawLine(Offset(0, y), Offset(w, y), p);
    }
    // вертикали (уходят в перспективу)
    final n = (15 * d).round().clamp(8, 20);
    for (var i = 0; i < n; i++) {
      final x = (i / (n - 1)) * w;
      final path = Path()
        ..moveTo(x, h)
        ..lineTo(w / 2 + (x - w / 2) * 0.05, horizon);
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _SynthwavePainter o) => o.t != t;
}

class _CrtPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _CrtPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // сканлайны
    final p = Paint()..color = Colors.black.withOpacity(0.15);
    for (double y = 0; y < h; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, w, 1), p);
    }
    // шум
    final n = (200 * d).round().clamp(50, 400);
    for (var i = 0; i < n; i++) {
      final x = _jit(i, t.floor().toDouble() + 0.1) * w;
      final y = _jit(i, t.floor().toDouble() + 0.3) * h;
      canvas.drawCircle(Offset(x, y), 1,
          Paint()..color = base.withOpacity(0.3));
    }
  }

  @override
  bool shouldRepaint(covariant _CrtPainter o) => o.t != t;
}

class _TerminalPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _TerminalPainter(this.t, this.base, this.d);
  static const lines = [
    '> initializing zapret...',
    '> loading configs...',
    '> service.bat started',
    '> winws --dpi-desync...',
    '> bypass active',
    '> ping: 24ms',
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final totalChars = (t * 30).floor();
    for (var i = 0; i < lines.length; i++) {
      final lineChars = (totalChars - i * 20).clamp(0, lines[i].length);
      if (lineChars <= 0) continue;
      final txt = lines[i].substring(0, lineChars);
      final y = 40.0 + i * 24;
      if (y > h) continue;
      _cachedTp(txt, base.withOpacity(0.7), 14).paint(canvas, Offset(40, y));
    }
    // курсор
    if (t.floor() % 2 == 0) {
      final lineIdx = (totalChars / 20).floor().clamp(0, lines.length - 1);
      final charsShown = (totalChars - lineIdx * 20).clamp(0, lines[lineIdx].length);
      final y = 40.0 + lineIdx * 24;
      canvas.drawRect(Rect.fromLTWH(40 + charsShown * 8.4, y, 8, 18),
          Paint()..color = base);
    }
  }

  @override
  bool shouldRepaint(covariant _TerminalPainter o) => o.t != t;
}

class _RadarPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _RadarPainter(this.t, this.base, this.d);
  static const _tau = 2 * math.pi;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;
    final r = math.min(w, h) * 0.4;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = base.withOpacity(0.3);
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(Offset(cx, cy), r * i / 4, p);
    }
    canvas.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), p);
    canvas.drawLine(Offset(cx, cy - r), Offset(cx, cy + r), p);
    // развёртка
    final angle = t * 1.5;
    final path = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx + math.cos(angle) * r, cy + math.sin(angle) * r);
    canvas.drawPath(
        path, Paint()..color = base..strokeWidth = 2..style = PaintingStyle.stroke);
    // след
    for (var k = 0; k < 30; k++) {
      final a = angle - k * 0.03;
      canvas.drawPath(
        Path()
          ..moveTo(cx, cy)
          ..lineTo(cx + math.cos(a) * r, cy + math.sin(a) * r),
        Paint()
          ..color = base.withOpacity((1 - k / 30) * 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    // точки
    final n = (6 * d).round().clamp(3, 10);
    for (var i = 0; i < n; i++) {
      final br = _jit(i, 0.3);
      final ba = _jit(i, 0.7) * _tau;
      final x = cx + math.cos(ba) * r * br;
      final y = cy + math.sin(ba) * r * br;
      final diff = ((angle - ba) % _tau + _tau) % _tau;
      if (diff < 1) {
        canvas.drawCircle(Offset(x, y), 3,
            Paint()..color = base.withOpacity((1 - diff)));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter o) => o.t != t;
}

class _OscPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _OscPainter(this.t, this.base, this.d);
  static const _tau = 2 * math.pi;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;
    final amp = math.min(w, h) * 0.3;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = base;
    final path = Path();
    final fa = 3 + d;
    final fb = 2 + d * 0.5;
    for (var i = 0; i <= 200; i++) {
      final s = i / 200 * _tau;
      final x = cx + math.sin(fa * s + t) * amp;
      final y = cy + math.sin(fb * s) * amp;
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _OscPainter o) => o.t != t;
}

class _VhsPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _VhsPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // сканлайны
    for (double y = 0; y < h; y += 2) {
      canvas.drawRect(
          Rect.fromLTWH(0, y, w, 1),
          Paint()..color = Colors.black.withOpacity(0.1));
    }
    // горизонтальные помехи
    final n = (10 * d).round().clamp(4, 20);
    for (var i = 0; i < n; i++) {
      final y = ((_jit(i, t.floor().toDouble() + 0.5) * h) + t * 100) % h;
      final width = 20 + _jit(i, 0.3) * 100;
      final x = _jit(i, 0.7) * w;
      canvas.drawRect(Rect.fromLTWH(x, y, width, 2),
          Paint()..color = base.withOpacity(0.5));
    }
  }

  @override
  bool shouldRepaint(covariant _VhsPainter o) => o.t != t;
}

class _PixelCloudsPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _PixelCloudsPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final px = 8.0;
    final n = (12 * d).round().clamp(4, 20);
    for (var i = 0; i < n; i++) {
      final spd = 0.1 + _jit(i, 0.3) * 0.2;
      var x = ((_jit(i, 0.7) * w * 2 + t * spd * 60) % (w + 200)) - 100;
      final y = (_jit(i, 0.9) * h * 0.7 + h * 0.15);
      final p = Paint()..color = base.withOpacity(0.6);
      // пиксельное облако
      final shape = [
        [0, 1, 1, 1, 0],
        [1, 1, 1, 1, 1],
        [1, 1, 1, 1, 1],
      ];
      for (var r = 0; r < shape.length; r++) {
        for (var c = 0; c < shape[r].length; c++) {
          if (shape[r][c] == 1) {
            canvas.drawRect(
                Rect.fromLTWH(x + c * px, y + r * px, px, px), p);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelCloudsPainter o) => o.t != t;
}

// ═══════════════════════════════════════════════════════════
// 🎨 АБСТРАКЦИЯ (33-40)
// ═══════════════════════════════════════════════════════════

class _RibbonsPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _RibbonsPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = (6 * d).round().clamp(3, 10);
    for (var i = 0; i < n; i++) {
      final ph = _jit(i, 0.3) * 6.28;
      final path = Path();
      for (double x = -50; x <= w + 50; x += 20) {
        final y = h / 2 +
            math.sin(x * 0.008 + t * (1 + i * 0.2) + ph) * 100 +
            math.cos(x * 0.015 - t * 0.7 + i) * 40 +
            i * 20 - n * 10;
        if (x <= -50) path.moveTo(x, y);
        else path.lineTo(x, y);
      }
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = base.withOpacity(0.4 - i * 0.03));
    }
  }

  @override
  bool shouldRepaint(covariant _RibbonsPainter o) => o.t != t;
}

class _KaleidoPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _KaleidoPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;
    final slices = 8;
    for (var s = 0; s < slices; s++) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(s * 6.28 / slices + t * 0.2);
      final n = (10 * d).round().clamp(4, 20);
      for (var i = 0; i < n; i++) {
        final r = 20.0 + i * 15;
        final a = math.sin(t + i * 0.5) * 0.5;
        final x = math.cos(a) * r;
        final y = math.sin(a) * r;
        canvas.drawCircle(
            Offset(x, y),
            3 + math.sin(t + i) * 2,
            Paint()..color = base.withOpacity(0.6 - i * 0.04));
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _KaleidoPainter o) => o.t != t;
}

class _MandalaPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _MandalaPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = base.withOpacity(0.5);
    for (var ring = 1; ring <= 6; ring++) {
      final r = ring * 30.0;
      final rot = t * (ring % 2 == 0 ? 0.3 : -0.3);
      final petals = 6 + ring * 2;
      for (var i = 0; i < petals; i++) {
        final a = i * 6.28 / petals + rot;
        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(a);
        canvas.drawOval(Rect.fromLTWH(r - 8, -3, 16, 6), p);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MandalaPainter o) => o.t != t;
}

class _TopoPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _TopoPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final n = (12 * d).round().clamp(5, 20);
    for (var i = 0; i < n; i++) {
      p.color = base.withOpacity(0.3 - i * 0.01);
      final path = Path();
      for (double x = 0; x <= w; x += 20) {
        final y = h * 0.3 +
            i * 15 +
            math.sin(x * 0.008 + t * 0.3 + i * 0.5) * 30 +
            math.cos(x * 0.012 - t * 0.2) * 15;
        if (x == 0) path.moveTo(x, y);
        else path.lineTo(x, y);
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _TopoPainter o) => o.t != t;
}

class _HexPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _HexPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final hexSize = 20.0;
    final cols = (w / (hexSize * 1.5)).ceil();
    final rows = (h / (hexSize * 1.732)).ceil();
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final x = c * hexSize * 1.5;
        final y = r * hexSize * 1.732 + (c % 2) * hexSize * 0.866;
        final dist = math.sqrt(math.pow(x - w / 2, 2) + math.pow(y - h / 2, 2));
        final wave = math.sin(dist * 0.02 - t * 2) * 0.5 + 0.5;
        p.color = base.withOpacity(wave * 0.6);
        final path = Path();
        for (var k = 0; k < 6; k++) {
          final a = k * 6.28 / 6;
          final px = x + math.cos(a) * hexSize * 0.5;
          final py = y + math.sin(a) * hexSize * 0.5;
          if (k == 0) path.moveTo(px, py);
          else path.lineTo(px, py);
        }
        path.close();
        canvas.drawPath(path, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HexPainter o) => o.t != t;
}

class _PulsarPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _PulsarPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;
    final n = (15 * d).round().clamp(6, 25);
    for (var i = 0; i < n; i++) {
      final life = (t * 0.5 + i / n) % 1.0;
      final r = life * math.max(w, h) * 0.6;
      final alpha = (1 - life) * 0.5;
      canvas.drawCircle(
          Offset(cx, cy),
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = base.withOpacity(alpha));
    }
  }

  @override
  bool shouldRepaint(covariant _PulsarPainter o) => o.t != t;
}

class _VoronoiPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _VoronoiPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = (20 * d).round().clamp(8, 30);
    final pts = <Offset>[];
    for (var i = 0; i < n; i++) {
      final bx = _jit(i, 0.3) * w;
      final by = _jit(i, 0.7) * h;
      final x = bx + math.sin(t * 0.5 + i) * 20;
      final y = by + math.cos(t * 0.4 + i * 1.3) * 20;
      pts.add(Offset(x, y));
    }
    // рёбра между ближайшими точками
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = base.withOpacity(0.4);
    for (var i = 0; i < n; i++) {
      for (var k = i + 1; k < n; k++) {
        final dist = (pts[i] - pts[k]).distance;
        if (dist < 150) {
          canvas.drawLine(pts[i], pts[k], p);
        }
      }
      canvas.drawCircle(pts[i], 2, Paint()..color = base);
    }
  }

  @override
  bool shouldRepaint(covariant _VoronoiPainter o) => o.t != t;
}

class _BubblesPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _BubblesPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = (25 * d).round().clamp(10, 60);
    for (var i = 0; i < n; i++) {
      final ph = _jit(i, 0.3) * 6.28;
      final bx = _jit(i, 0.7) * w;
      final by = _jit(i, 0.9) * h;
      final x = bx + math.sin(t * 0.5 + ph) * 30;
      final y = by + math.cos(t * 0.4 + ph) * 30;
      final r = 10 + _jit(i, 0.5) * 30;
      canvas.drawCircle(
          Offset(x, y),
          r,
          Paint()
            ..shader = ui.Gradient.radial(
                Offset(x - r * 0.3, y - r * 0.3), r,
                [base.withOpacity(0.3), base.withOpacity(0.1), Colors.transparent]));
      canvas.drawCircle(
          Offset(x, y),
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = base.withOpacity(0.4));
      // блик
      canvas.drawCircle(Offset(x - r * 0.3, y - r * 0.3), r * 0.2,
          Paint()..color = Colors.white.withOpacity(0.4));
    }
  }

  @override
  bool shouldRepaint(covariant _BubblesPainter o) => o.t != t;
}

// ═══════════════════════════════════════════════════════════
// 🏙 УЮТ (41-46)
// ═══════════════════════════════════════════════════════════

class _NightCityPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _NightCityPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final ground = h * 0.7;
    // здания
    final n = (20 * d).round().clamp(8, 30);
    for (var i = 0; i < n; i++) {
      final bw = 30 + _jit(i, 0.3) * 60;
      final bh = 50 + _jit(i, 0.7) * (h - ground - 50);
      final x = _jit(i, 0.9) * w;
      final y = ground - bh;
      canvas.drawRect(
          Rect.fromLTWH(x, y, bw, bh),
          Paint()..color = Colors.black.withOpacity(0.8));
      // окна
      final rows = (bh / 15).floor();
      final cols = (bw / 12).floor();
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          final on = ((_jit(i * 100 + r * 10 + c, 0.5) + math.sin(t * 0.1 + i + r) * 0.1) > 0.4);
          if (on) {
            canvas.drawRect(
                Rect.fromLTWH(x + 4 + c * 12, y + 4 + r * 15, 6, 8),
                Paint()..color = base.withOpacity(0.8));
          }
        }
      }
    }
    canvas.drawRect(Rect.fromLTWH(0, ground, w, h - ground),
        Paint()..color = Colors.black.withOpacity(0.9));
  }

  @override
  bool shouldRepaint(covariant _NightCityPainter o) => o.t != t;
}

class _NeonPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _NeonPainter(this.t, this.base, this.d);
  static const words = ['ZAPRET', 'OPEN', '24/7', 'ON', 'FLOW'];
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = (8 * d).round().clamp(4, 12);
    for (var i = 0; i < n; i++) {
      final x = _jit(i, 0.3) * (w - 100);
      final y = _jit(i, 0.7) * (h - 40) + 20;
      final word = words[i % words.length];
      final flicker = 0.7 + 0.3 * (0.5 + 0.5 * math.sin(t * 8 + i * 3));
      final fB = (flicker * 10).round() / 10;
      final core = base.withOpacity(fB);
      final tp = _cachedTp(word, core, 20, weight: FontWeight.w900);
      canvas.drawRect(
          Rect.fromLTWH(x - 10, y - 5, tp.width + 20, tp.height + 10),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..color = base.withOpacity(fB * 0.35));
      canvas.drawRect(
          Rect.fromLTWH(x - 10, y - 5, tp.width + 20, tp.height + 10),
          Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = core);
      tp.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant _NeonPainter o) => o.t != t;
}

class _FireplacePainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _FireplacePainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2, baseY = h * 0.8;
    // угли
    final n = (15 * d).round().clamp(6, 25);
    for (var i = 0; i < n; i++) {
      final x = cx + (_jit(i, 0.3) - 0.5) * 200;
      final y = baseY + _jit(i, 0.7) * 20;
      final pulse = 0.5 + 0.5 * math.sin(t * 3 + i);
      canvas.drawCircle(
          Offset(x, y),
          4 + _jit(i, 0.9) * 4,
          Paint()..color = const Color(0xFFFF4500).withOpacity(pulse));
    }
    // огонь
    final flames = 20;
    for (var i = 0; i < flames; i++) {
      final x = cx + (_jit(i, 0.1) - 0.5) * 120;
      final flameH = 60 + math.sin(t * 4 + i) * 30 + _jit(i, 0.5) * 40;
      final path = Path()
        ..moveTo(x - 10, baseY)
        ..quadraticBezierTo(
            x + math.sin(t * 5 + i) * 20, baseY - flameH / 2, x, baseY - flameH)
        ..quadraticBezierTo(
            x - math.sin(t * 5 + i) * 20, baseY - flameH / 2, x + 10, baseY)
        ..close();
      canvas.drawPath(
          path,
          Paint()
            ..shader = ui.Gradient.linear(
                Offset(x, baseY), Offset(x, baseY - flameH),
                [const Color(0xFFFF8C00).withOpacity(0.7), const Color(0xFFFF4500).withOpacity(0.3), Colors.transparent]));
    }
    // искры
    final sparks = (20 * d).round().clamp(6, 40);
    for (var i = 0; i < sparks; i++) {
      final spd = 0.5 + _jit(i, 0.3) * 0.8;
      final ph = _jit(i, 0.7);
      final life = (t * spd + ph) % 1.0;
      final x = cx + (_jit(i, 0.9) - 0.5) * 100 + math.sin(t + i) * 20;
      final y = baseY - life * 300;
      canvas.drawCircle(Offset(x, y), 1.5,
          Paint()..color = const Color(0xFFFFD700).withOpacity((1 - life)));
    }
  }

  @override
  bool shouldRepaint(covariant _FireplacePainter o) => o.t != t;
}

class _VinylPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _VinylPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;
    final r = math.min(w, h) * 0.35;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(t * 2);
    // основа
    canvas.drawCircle(Offset.zero, r,
        Paint()..color = Colors.black.withOpacity(0.9));
    // дорожки
    for (var i = 5; i < 30; i++) {
      canvas.drawCircle(
          Offset.zero,
          r * (i / 30),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.3
            ..color = Colors.white.withOpacity(0.1));
    }
    // этикетка
    canvas.drawCircle(Offset.zero, r * 0.25,
        Paint()..color = base.withOpacity(0.8));
    // блик
    canvas.restore();
    canvas.drawCircle(
        Offset(cx - r * 0.3, cy - r * 0.3),
        r * 0.8,
        Paint()
          ..shader = ui.Gradient.radial(
              Offset(cx - r * 0.3, cy - r * 0.3), r * 0.8,
              [Colors.white.withOpacity(0.15), Colors.transparent]));
  }

  @override
  bool shouldRepaint(covariant _VinylPainter o) => o.t != t;
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _ConfettiPainter(this.t, this.base, this.d);
  static const cols = [
    Color(0xFFEF476F),
    Color(0xFF06D6A0),
    Color(0xFF118AB2),
    Color(0xFFFFD166),
    Color(0xFFFFFFFF),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = (60 * d).round().clamp(20, 150);
    for (var i = 0; i < n; i++) {
      final spd = 0.2 + _jit(i, 0.3) * 0.4;
      final ph = _jit(i, 0.7);
      final life = (t * spd + ph) % 1.0;
      final y = -20 + life * (h + 40);
      final x = _jit(i, 0.9) * w + math.sin(t * 2 + ph * 5) * 30;
      final rot = t * 3 + ph * 10;
      final c = cols[i % cols.length];
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      canvas.drawRect(
          Rect.fromLTWH(-4, -2, 8, 4),
          Paint()..color = c.withOpacity(0.9));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter o) => o.t != t;
}

class _PlanesPainter extends CustomPainter {
  final double t;
  final Color base;
  final double d;
  _PlanesPainter(this.t, this.base, this.d);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final n = (5 * d).round().clamp(2, 10);
    for (var i = 0; i < n; i++) {
      final spd = 0.3 + _jit(i, 0.3) * 0.5;
      final ph = _jit(i, 0.7);
      final life = (t * spd + ph) % 1.0;
      final x = -50 + life * (w + 100);
      final y = _jit(i, 0.9) * h * 0.7 + h * 0.15 +
          math.sin(t * 2 + ph * 3) * 20;
      final rot = math.sin(t + ph) * 0.3;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      final p = Paint()..color = base.withOpacity(0.8);
      // треугольник-самолётик
      final path = Path()
        ..moveTo(-15, 0)
        ..lineTo(15, -4)
        ..lineTo(15, 4)
        ..close();
      canvas.drawPath(path, p);
      // крыло
      canvas.drawPath(
          Path()
            ..moveTo(-5, 0)
            ..lineTo(-10, -8)
            ..lineTo(5, -2)
            ..close(),
          p);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PlanesPainter o) => o.t != t;
}