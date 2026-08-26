import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/app_visibility.dart';
import '../../core/ui_settings.dart';

Widget backgroundDecor(Color bg) => Container(color: bg);

// 🎲 детерминированный «рандом» для добавочных объектов при плотности > 1
double _jit(int i, double salt) => (i * 0.61803398875 + salt) % 1.0;

class LiveBackground extends StatefulWidget {
  final Color color;
  final double speed;
  final int style;
  final double density;
  const LiveBackground({
    super.key,
    required this.color,
    this.speed = 1.0,
    this.style = 0,
    this.density = 1.0,
  });
  @override
  State<LiveBackground> createState() => _LiveBackgroundState();
}

class _LiveBackgroundState extends State<LiveBackground> {
  double _t = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    AppVisibility.visible.addListener(_restart);
    UiSettings.fpsCap.addListener(_restart);
    UiSettings.ecoMode.addListener(_restart);
    _restart();
  }

  void _restart() {
    _timer?.cancel();
    _timer = null;
    // 🚦 окно скрыто — не анимируем вообще
    if (!AppVisibility.visible.value) return;
    // 🎛 кап FPS из настроек: в эко-режиме жёстко 12
    final cap = UiSettings.ecoMode.value
        ? 12
        : UiSettings.fpsCap.value.clamp(12, 60);
    final stepMs = 1000 ~/ cap;
    final cycleMs = 34000 / widget.speed;
    _timer = Timer.periodic(Duration(milliseconds: stepMs), (_) {
      if (!mounted) return;
      setState(() => _t = (_t + stepMs / cycleMs) % 1.0);
    });
  }

  @override
  void didUpdateWidget(LiveBackground old) {
    super.didUpdateWidget(old);
    if (old.speed != widget.speed) _restart();
  }

  @override
  void dispose() {
    AppVisibility.visible.removeListener(_restart);
    UiSettings.fpsCap.removeListener(_restart);
    UiSettings.ecoMode.removeListener(_restart);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(
          size: Size.infinite,
          painter: widget.style == 1
              ? _WavesPainter(_t, widget.color, widget.density)
              : widget.style == 2
                  ? _StarsPainter(_t, widget.color, widget.density)
                  : widget.style == 3
                      ? _YWavePainter(_t, widget.color)
                      : widget.style == 4
                          ? _CloudsPainter(_t, widget.color, widget.density)
                          : widget.style == 5
                              ? _DucksPainter(_t, widget.color, widget.density)
                              : widget.style == 6
                                  ? _FrogsPainter(_t, widget.color, widget.density)
                                  : widget.style == 7
                                      ? _DotsPainter(_t, widget.color, widget.density)
                                      : widget.style == 8
                                          ? _AquariumPainter(_t, widget.color, widget.density)
                                          : _AuroraPainter(_t, widget.color, widget.density),
        ),
      );
}

// ── 🌌 Аврора: мягкие дрейфующие пятна ─────────────────────
class _Blob {
  final int fx, fy;
  final double px, py, ax, ay, r, o;
  const _Blob(
      this.fx, this.fy, this.px, this.py, this.ax, this.ay, this.r, this.o);
}

class _AuroraPainter extends CustomPainter {
  final double t;
  final Color base;
  final double density;
  _AuroraPainter(this.t, this.base, this.density);
  static const double _tau = 2 * math.pi;
  static const List<_Blob> _blobs = [
    _Blob(1, 1, 0.00, 0.10, 0.38, 0.32, 0.45, 0.45),
    _Blob(1, 2, 0.35, 0.60, 0.34, 0.38, 0.38, 0.34),
    _Blob(2, 1, 0.62, 0.25, 0.30, 0.34, 0.34, 0.30),
    _Blob(2, 3, 0.80, 0.45, 0.26, 0.26, 0.28, 0.24),
    _Blob(3, 2, 0.15, 0.85, 0.22, 0.22, 0.24, 0.20),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    final n = (_blobs.length * density).round().clamp(1, 12);
    for (var i = 0; i < n; i++) {
      final b = _blobs[i % _blobs.length];
      final rep = i ~/ _blobs.length;
      final px = (b.px + 0.37 * rep) % 1.0;
      final py = (b.py + 0.29 * rep) % 1.0;
      final x = w * (0.5 + b.ax * math.sin(_tau * (t * b.fx + px)));
      final y = h * (0.5 + b.ay * math.cos(_tau * (t * b.fy + py)));
      final r = math.max(w, h) *
          b.r *
          (rep == 0 ? 1.0 : 0.7) *
          (0.9 + 0.1 * math.sin(_tau * (t + px)));
      canvas.drawRect(
        Rect.fromLTRB(x - r, y - r, x + r, y + r),
        Paint()
          ..shader = ui.Gradient.radial(Offset(x, y), r,
              [base.withOpacity(b.o), base.withOpacity(0.0)]),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => old.t != t;
}

// ── 🦆🐸 общие параметры дрейфа ───────────
class _Drift {
  final double y, s, p, o;
  const _Drift(this.y, this.s, this.p, this.o);
}

// ── 🦆 Утки: силуэты плывут ВЛЕВО с покачиванием ───────────
class _DucksPainter extends CustomPainter {
  final double t;
  final Color base;
  final double density;
  _DucksPainter(this.t, this.base, this.density);
  static const double _tau = 2 * math.pi;
  static const List<_Drift> _items = [
    _Drift(0.16, 1.10, 0.10, 0.10),
    _Drift(0.38, 0.75, 0.45, 0.07),
    _Drift(0.58, 1.35, 0.70, 0.11),
    _Drift(0.78, 0.90, 0.30, 0.08),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    final tint = Color.lerp(Colors.white, base, 0.2)!;
    final n = (_items.length * density).round().clamp(1, 16);
    for (var i = 0; i < n; i++) {
      final b = _items[i % _items.length];
      final rep = i ~/ _items.length;
      final c = _Drift((b.y + 0.17 * rep) % 1.0, b.s * (rep == 0 ? 1.0 : 0.75),
          (b.p + 0.41 * rep) % 1.0, b.o);
      final s = w * 0.10 * c.s;
      final cw = s * 1.2;
      final travel = w + cw * 2;
      double x = (c.p - t) % 1.0;
      if (x < 0) x += 1.0;
      final cx = x * travel - cw;
      final bob = math.sin(_tau * (t * 3 + c.p)) * h * 0.008;
      canvas.drawPath(
        _duck(cx, h * c.y + bob, s),
        Paint()
          ..color = tint.withOpacity(c.o)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
      );
    }
  }

  /// утка: тело + хвост + шея + голова + клюв (один Path → ровная заливка)
  Path _duck(double x, double y, double s) {
    return Path()
      ..addOval(Rect.fromLTWH(x, y, s, s * 0.42))
      ..moveTo(x + s * 0.92, y + s * 0.12)
      ..lineTo(x + s * 1.14, y - s * 0.10)
      ..lineTo(x + s * 0.82, y + s * 0.04)
      ..close()
      ..addRect(Rect.fromLTWH(x + s * 0.10, y - s * 0.24, s * 0.16, s * 0.34))
      ..addOval(Rect.fromCircle(
          center: Offset(x + s * 0.18, y - s * 0.26), radius: s * 0.15))
      ..moveTo(x + s * 0.05, y - s * 0.30)
      ..lineTo(x - s * 0.12, y - s * 0.24)
      ..lineTo(x + s * 0.05, y - s * 0.18)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _DucksPainter old) => old.t != t;
}

// ── 🐸 Лягушки: силуэты скачут ВЛЕВО ───────────
class _FrogsPainter extends CustomPainter {
  final double t;
  final Color base;
  final double density;
  _FrogsPainter(this.t, this.base, this.density);
  static const List<_Drift> _items = [
    _Drift(0.18, 0.90, 0.15, 0.09),
    _Drift(0.42, 1.20, 0.55, 0.11),
    _Drift(0.66, 0.70, 0.80, 0.07),
    _Drift(0.86, 1.00, 0.35, 0.09),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    final tint = Color.lerp(Colors.white, base, 0.2)!;
    final n = (_items.length * density).round().clamp(1, 16);
    for (var i = 0; i < n; i++) {
      final b = _items[i % _items.length];
      final rep = i ~/ _items.length;
      final c = _Drift((b.y + 0.17 * rep) % 1.0, b.s * (rep == 0 ? 1.0 : 0.75),
          (b.p + 0.41 * rep) % 1.0, b.o);
      final s = w * 0.09 * c.s;
      final cw = s * 1.1;
      final travel = w + cw * 2;
      double x = (c.p - t) % 1.0;
      if (x < 0) x += 1.0;
      final cx = x * travel - cw;
      // 🐾 прыжок: горб sin = подскок
      final hop =
          -math.sin(math.pi * ((t * 4 + c.p) % 1.0)).abs() * h * 0.02;
      canvas.drawPath(
        _frog(cx, h * c.y + hop, s),
        Paint()
          ..color = tint.withOpacity(c.o)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
      );
    }
  }

  /// лягушка: тело + два глаза + лапки
  Path _frog(double x, double y, double s) {
    return Path()
      ..addOval(Rect.fromLTWH(x, y, s, s * 0.55))
      ..addOval(Rect.fromCircle(
          center: Offset(x + s * 0.28, y + s * 0.02), radius: s * 0.16))
      ..addOval(Rect.fromCircle(
          center: Offset(x + s * 0.72, y + s * 0.02), radius: s * 0.16))
      ..addOval(Rect.fromLTWH(x + s * 0.06, y + s * 0.42, s * 0.20, s * 0.18))
      ..addOval(Rect.fromLTWH(x + s * 0.74, y + s * 0.42, s * 0.20, s * 0.18));
  }

  @override
  bool shouldRepaint(covariant _FrogsPainter old) => old.t != t;
}

// ── 🌊 Волны: три синусоиды, целые частоты = цикл без шва ──
class _WavesPainter extends CustomPainter {
  final double t;
  final Color base;
  final double density;
  _WavesPainter(this.t, this.base, this.density);
  static const double _tau = 2 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    final lines = (3 * density).round().clamp(1, 8);
    for (var l = 0; l < lines; l++) {
      final yBase = h * (0.28 + 0.22 * l);
      final amp = h * (0.05 + 0.02 * l);
      final freq = 1.5 + l * 0.5;
      final path = Path();
      for (double x = 0; x <= w; x += 8) {
        final y = yBase + math.sin(_tau * (t * (l + 1) + (x / w) * freq)) * amp;
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.6 + l * 0.6
          ..color = base.withOpacity(0.28 - 0.07 * l),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavesPainter old) => old.t != t;
}

// ── ✨ Звёзды: дрейф вверх + мерцание, ~28 точек ───────────
class _Star {
  final double x, y, s, p, v;
  const _Star(this.x, this.y, this.s, this.p, this.v);
}

class _StarsPainter extends CustomPainter {
  final double t;
  final Color base;
  final double density;
  _StarsPainter(this.t, this.base, this.density);
  static const double _tau = 2 * math.pi;
  static const List<_Star> _stars = [
    _Star(0.05, 0.10, 1.6, 0.00, 0.5),
    _Star(0.12, 0.42, 1.1, 0.35, 0.3),
    _Star(0.18, 0.78, 1.8, 0.60, 0.7),
    _Star(0.24, 0.22, 1.0, 0.15, 0.4),
    _Star(0.30, 0.60, 1.4, 0.80, 0.6),
    _Star(0.36, 0.05, 1.2, 0.45, 0.5),
    _Star(0.42, 0.88, 1.7, 0.25, 0.8),
    _Star(0.48, 0.35, 1.0, 0.70, 0.3),
    _Star(0.55, 0.65, 1.5, 0.05, 0.6),
    _Star(0.60, 0.15, 1.1, 0.55, 0.4),
    _Star(0.66, 0.50, 1.9, 0.90, 0.7),
    _Star(0.72, 0.82, 1.0, 0.30, 0.5),
    _Star(0.78, 0.28, 1.4, 0.65, 0.6),
    _Star(0.84, 0.70, 1.2, 0.10, 0.4),
    _Star(0.90, 0.40, 1.7, 0.50, 0.8),
    _Star(0.95, 0.08, 1.1, 0.75, 0.3),
    _Star(0.08, 0.92, 1.3, 0.20, 0.6),
    _Star(0.22, 0.55, 1.0, 0.95, 0.4),
    _Star(0.38, 0.30, 1.6, 0.40, 0.7),
    _Star(0.52, 0.90, 1.1, 0.85, 0.5),
    _Star(0.68, 0.12, 1.4, 0.55, 0.6),
    _Star(0.82, 0.48, 1.0, 0.35, 0.4),
    _Star(0.93, 0.75, 1.5, 0.65, 0.7),
    _Star(0.15, 0.25, 1.2, 0.05, 0.5),
    _Star(0.45, 0.55, 1.0, 0.30, 0.3),
    _Star(0.62, 0.38, 1.3, 0.75, 0.6),
    _Star(0.75, 0.95, 1.1, 0.15, 0.4),
    _Star(0.88, 0.20, 1.6, 0.45, 0.8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    final n = (_stars.length * density).round().clamp(4, 80);
    for (var i = 0; i < n; i++) {
      final s = i < _stars.length
          ? _stars[i]
          : _Star(_jit(i, 0.13), _jit(i, 0.71), 1.0 + _jit(i, 0.31) * 0.9,
              _jit(i, 0.57), 0.3 + _jit(i, 0.93) * 0.5);
      final y = (((s.y - t * s.v) % 1) + 1) % 1;
      final tw = 0.5 + 0.5 * math.sin(_tau * (t * 2 + s.p));
      final o = 0.10 + 0.45 * tw;
      final r = s.s * (0.8 + 0.4 * tw);
      canvas.drawCircle(Offset(s.x * w, y * h), r,
          Paint()..color = base.withOpacity(o));
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter old) => old.t != t;
}

// ── ☁️ Облака: силуэты-иконки плывут ВЛЕВО ───────────
class _Cloud {
  final double y, s, p, o;
  const _Cloud(this.y, this.s, this.p, this.o);
}

class _CloudsPainter extends CustomPainter {
  final double t;
  final Color base;
  final double density;
  _CloudsPainter(this.t, this.base, this.density);

  static const List<_Cloud> _clouds = [
    _Cloud(0.10, 1.30, 0.05, 0.10),
    _Cloud(0.28, 0.80, 0.42, 0.07),
    _Cloud(0.46, 1.60, 0.68, 0.12),
    _Cloud(0.63, 0.70, 0.22, 0.06),
    _Cloud(0.80, 1.10, 0.55, 0.09),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    final tint = Color.lerp(Colors.white, base, 0.2)!;
    final n = (_clouds.length * density).round().clamp(1, 20);
    for (var i = 0; i < n; i++) {
      final b = _clouds[i % _clouds.length];
      final rep = i ~/ _clouds.length;
      final c = _Cloud((b.y + 0.17 * rep) % 1.0, b.s * (rep == 0 ? 1.0 : 0.75),
          (b.p + 0.41 * rep) % 1.0, b.o);
      final s = w * 0.16 * c.s; // масштаб облака
      final cw = s * 1.6; // его ширина
      final travel = w + cw * 2;
      double x = (c.p - t) % 1.0; // дрейф ВЛЕВО, цикл без шва
      if (x < 0) x += 1.0;
      final cx = x * travel - cw;
      final cy = h * c.y;
      canvas.drawPath(
        _cloud(cx, cy, s),
        Paint()
          ..color = tint.withOpacity(c.o)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }

  Path _cloud(double x, double y, double s) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, s * 1.6, s * 0.5),
          Radius.circular(s * 0.25)))
      ..addOval(Rect.fromCircle(
          center: Offset(x + s * 0.55, y - s * 0.05), radius: s * 0.32))
      ..addOval(Rect.fromCircle(
          center: Offset(x + s * 1.0, y + s * 0.02), radius: s * 0.22));
  }

  @override
  bool shouldRepaint(covariant _CloudsPainter old) => old.t != t;
}

// ── 🎵 «Моя волна» как в Яндекс Музыке ────────────
class _YWavePainter extends CustomPainter {
  final double t;
  final Color base;
  _YWavePainter(this.t, this.base);
  static const double _tau = 2 * math.pi;

  // ⚡ Переиспользуемый Path — 0 аллокаций в кадре
  static final Path _blobPath = Path();

  double _w(double a, double t) =>
      1.0 +
      0.14 * math.sin(3 * a + _tau * t) +
      0.10 * math.sin(5 * a - _tau * 2 * t + 1.7) +
      0.06 * math.sin(8 * a + _tau * 3 * t + 4.1);

  Path _blob(double cx, double cy, double R, double scale) {
    _blobPath.reset();
    const steps = 72;
    for (var i = 0; i <= steps; i++) {
      final a = i / steps * _tau;
      final r = R * scale * _w(a, t);
      final x = cx + r * math.cos(a);
      final y = cy + r * math.sin(a);
      if (i == 0) {
        _blobPath.moveTo(x, y);
      } else {
        _blobPath.lineTo(x, y);
      }
    }
    return _blobPath..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    final m = math.max(w, h);
    final cx = w * (0.5 + 0.05 * math.sin(_tau * t));
    final cy = h * (0.5 + 0.05 * math.cos(_tau * (2 * t + 0.25)));
    final R = math.min(w, h) * 0.30 * (1 + 0.06 * math.sin(_tau * (2 * t + 0.6)));
    final core = Color.lerp(base, Colors.white, 0.45)!;
    final line = Color.lerp(base, Colors.white, 0.7)!;

    // ── 0) 🔦 лучи-«фонарики» ─────────────────────────
    for (var i = 0; i < 9; i++) {
      final life = (t * (1 + i % 3) + i * 0.618) % 1.0;
      final vis = math.sin(math.pi * life);
      if (vis < 0.06) continue;
      final a =
          _tau * (i / 9) + i * 0.9 + 0.5 * math.sin(_tau * (t + i * 0.37));
      final r0 = R * (0.25 + 0.10 * math.sin(_tau * 2 * t + i));
      final len = m * (0.12 + 0.30 * vis) * (0.7 + 0.3 * math.sin(i * 2.3));
      final r1 = r0 + len;
      final w0 = 1.0 + 2.0 * vis;
      final w1 = w0 + len * 0.22;
      final dx = math.cos(a), dy = math.sin(a);
      final pxv = -dy, pyv = dx;
      final path = Path()
        ..moveTo(cx + dx * r0 - pxv * w0, cy + dy * r0 - pyv * w0)
        ..lineTo(cx + dx * r0 + pxv * w0, cy + dy * r0 + pyv * w0)
        ..lineTo(cx + dx * r1 + pxv * w1, cy + dy * r1 + pyv * w1)
        ..lineTo(cx + dx * r1 - pxv * w1, cy + dy * r1 - pyv * w1)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(cx + dx * r0, cy + dy * r0),
            Offset(cx + dx * r1, cy + dy * r1),
            [
              line.withOpacity(0.30 * vis),
              line.withOpacity(0.12 * vis),
              line.withOpacity(0.0),
            ],
            [0.0, 0.5, 1.0],
          ),
      );
    }

    // ── 1) мягкое внешнее гало ───────────────────────────────
    canvas.drawPath(
      _blob(cx, cy, R, 1.15),
      Paint()
        ..shader = ui.Gradient.radial(Offset(cx, cy), R * 1.35, [
          core.withOpacity(0.45),
          base.withOpacity(0.28),
          base.withOpacity(0.0)
        ], [
          0.0,
          0.45,
          1.0
        ]),
    );

    // ── 2) деформирующийся силуэт облака ─────────────────────
    canvas.drawPath(
      _blob(cx, cy, R, 0.92),
      Paint()
        ..shader = ui.Gradient.radial(Offset(cx, cy), R * 1.1, [
          core.withOpacity(0.55),
          base.withOpacity(0.30),
          base.withOpacity(0.0)
        ], [
          0.0,
          0.6,
          1.0
        ]),
    );

    // ── 3) яркое ядро ────────────────────────────────────────
    canvas.drawPath(
      _blob(cx, cy, R * 0.55, 1.0),
      Paint()
        ..shader = ui.Gradient.radial(
            Offset(cx, cy), R * 0.75, [core.withOpacity(0.50), core.withOpacity(0.0)]),
    );
  }

  @override
  bool shouldRepaint(covariant _YWavePainter old) =>
      old.t != t || old.base != base;
}

// ── ⚪ Точки: dot-сетка с волнами и угловыми «взрывами» (как на видео) ─────
class _DotsPainter extends CustomPainter {
  final double t;
  final Color base;
  final double density;
  _DotsPainter(this.t, this.base, this.density);
  static const double _tau = 2 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    final tint = Color.lerp(base, Colors.white, 0.5)!;
    final step = (16 / density).clamp(10.0, 28.0);
    final p = Paint();
    // сетка точек, дышащая волной по диагонали
    for (double y = step / 2; y < h; y += step) {
      for (double x = step / 2; x < w; x += step) {
        final v = math.sin((x + y) * 0.02 + _tau * t) *
            math.cos(x * 0.008 - _tau * t * 0.5);
        final k = 0.5 + 0.5 * v;
        p.color = tint.withOpacity(0.04 + 0.16 * k);
        canvas.drawCircle(Offset(x, y), 0.7 + 0.9 * k, p);
      }
    }
    // диагональные волнистые линии
    final lp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = tint.withOpacity(0.22);
    final n = (7 * density).round().clamp(3, 14);
    for (var l = 0; l < n; l++) {
      final off = l * (w + h) / n;
      final path = Path();
      for (double d = -h; d <= w + h; d += 12) {
        final x = d;
        final y =
            -d * 0.9 + off + math.sin(d * 0.01 + _tau * t + l * 1.7) * 14;
        if (d <= -h) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, lp);
    }
    // угловые «взрывы»: дышат, центр дрейфует, лучи шевелятся каждый сам
    for (var k = 0; k < 2; k++) {
      final c = k == 0 ? const Offset(0.95, 0.05) : const Offset(0.05, 0.95);
      final ph = k * 2.3;
      final cx = c.dx * w + math.sin(_tau * t * 0.4 + ph) * w * 0.012;
      final cy = c.dy * h + math.cos(_tau * t * 0.33 + ph) * h * 0.012;
      final r = math.max(w, h) *
          0.35 *
          (0.92 + 0.08 * math.sin(_tau * t * 0.6 + ph));
      canvas.drawRect(
        Rect.fromLTRB(cx - r, cy - r, cx + r, cy + r),
        Paint()
          ..shader = ui.Gradient.radial(Offset(cx, cy), r, [
            Colors.black
                .withOpacity(0.40 + 0.10 * math.sin(_tau * t * 0.5 + ph)),
            Colors.black.withOpacity(0.0),
          ]),
      );
      final rp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 0.7
        ..color = tint.withOpacity(0.18);
      for (var i = 0; i < 24; i++) {
        // каждый луч живёт своей жизнью: угол и длина шевелятся
        final a =
            i / 24 * _tau + math.sin(_tau * t * 0.5 + i * 1.7 + ph) * 0.10;
        final len = 0.45 +
            0.40 * (0.5 + 0.5 * math.sin(_tau * t * 0.8 + i * 0.9 + ph));
        canvas.drawLine(
          Offset(cx + math.cos(a) * r * 0.10, cy + math.sin(a) * r * 0.10),
          Offset(cx + math.cos(a) * r * len, cy + math.sin(a) * r * len),
          rp,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter old) => old.t != t;
}

// ── 🫧 Аквариум без рыбок: лучи, поверхность, пузыри ─────────────────────
class _AquariumPainter extends CustomPainter {
  final double t;
  final Color base;
  final double density;
  _AquariumPainter(this.t, this.base, this.density);
  static const double _tau = 2 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    final tint = Color.lerp(base, Colors.white, 0.55)!;

    // толща воды: сверху светлее, к дну темнее
    canvas.drawRect(
      Rect.fromLTRB(0, 0, w, h),
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, h), [
          base.withOpacity(0.16),
          base.withOpacity(0.06),
          Colors.black.withOpacity(0.25),
        ], [0.0, 0.5, 1.0]),
    );

    // 🫧 пузыри: сид фиксирован → каждый кадр тот же «случайный» набор,
    //    никакого узора по диагонали — настоящий разброс по аквариуму
    final rnd = math.Random(97531);
    final n = (18 * density).round().clamp(4, 70);
    for (var i = 0; i < n; i++) {
      final bx = rnd.nextDouble();
      final speed = 0.22 + rnd.nextDouble() * 0.55;
      final r = 1.5 + rnd.nextDouble() * 4.5;
      final ph = rnd.nextDouble();
      final drift = 6.0 + rnd.nextDouble() * 16.0;
      final life = (t * speed + ph) % 1.0;
      final y = h + 20 - life * (h + 40);
      final x = bx * w + math.sin(_tau * (t * 0.5 + ph) * 2) * drift;
      final fade =
          life < 0.1 ? life / 0.1 : (life > 0.9 ? (1 - life) / 0.1 : 1.0);
      canvas.drawCircle(
          Offset(x, y),
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0
            ..color = tint.withOpacity(0.35 * fade));
      canvas.drawCircle(
          Offset(x - r * 0.35, y - r * 0.35),
          r * 0.25,
          Paint()..color = tint.withOpacity(0.5 * fade));
    }
  }

  @override
  bool shouldRepaint(covariant _AquariumPainter old) => old.t != t;
}