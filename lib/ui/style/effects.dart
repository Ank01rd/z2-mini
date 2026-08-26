import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/app_visibility.dart';
import '../../core/ui_settings.dart';

Widget backgroundDecor(Color bg) => Container(color: bg);

/// 🌌 Единый живой фон: 0=аврора, 1=волны, 2=звёзды, 3=«Моя волна», 4=облака.
/// ⚡ Оптимизация: Timer с cap FPS, пауза при скрытом окне.
class LiveBackground extends StatefulWidget {
  final Color color;
  final double speed;
  final int style;
  const LiveBackground({
    super.key,
    required this.color,
    this.speed = 1.0,
    this.style = 0,
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
              ? _WavesPainter(_t, widget.color)
              : widget.style == 2
                  ? _StarsPainter(_t, widget.color)
                  : widget.style == 3
                      ? _YWavePainter(_t, widget.color)
                      : widget.style == 4
                          ? _CloudsPainter(_t, widget.color)
                          : _AuroraPainter(_t, widget.color),
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
  _AuroraPainter(this.t, this.base);
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
    for (final b in _blobs) {
      final x = w * (0.5 + b.ax * math.sin(_tau * (t * b.fx + b.px)));
      final y = h * (0.5 + b.ay * math.cos(_tau * (t * b.fy + b.py)));
      final r = math.max(w, h) * b.r * (0.9 + 0.1 * math.sin(_tau * (t + b.px)));
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

// ── 🌊 Волны: три синусоиды, целые частоты = цикл без шва ──
class _WavesPainter extends CustomPainter {
  final double t;
  final Color base;
  _WavesPainter(this.t, this.base);
  static const double _tau = 2 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    for (var l = 0; l < 3; l++) {
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
  _StarsPainter(this.t, this.base);
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
    for (final s in _stars) {
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
  _CloudsPainter(this.t, this.base);

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
    for (final c in _clouds) {
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