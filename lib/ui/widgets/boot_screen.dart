import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/ui_scale.dart';
import '../../core/ui_settings.dart';

/// 💫 Liquid-boot: кольцо-развёртка → ударные волны → капли →
///    пословное «Z2 MINI» → блик-сканлайн → вспышка и фейд
class BootScreen extends StatefulWidget {
  final VoidCallback onDone;
  final int durationMs;
  final String caption;
  const BootScreen(
      {super.key,
      required this.onDone,
      this.durationMs = 3500,
      this.caption = ''});
  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: Duration(milliseconds: widget.durationMs));

  Color get _accent =>
      UiSettings.accentColor.value ?? const Color(0xFF60A5FA);

  @override
  void initState() {
    super.initState();
    if (UiSettings.animationsEnabled.value) {
      _c.forward();
    } else {
      _c.value = 1;
    }
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _cl(double x) => x.clamp(0.0, 1.0);
  double _ez(double x) {
    x = _cl(x);
    return x * x * (3 - 2 * x);
  }

  double _back(double x) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    x = _cl(x);
    return 1 + c3 * math.pow(x - 1, 3) + c1 * math.pow(x - 1, 2);
  }

  static const _letters = ['Z', '2', ' ', 'M', 'I', 'N', 'I'];

  Widget _letter(int i, double t) {
    final ch = _letters[i];
    if (ch == ' ') return SizedBox(width: sc(10));
    final p = _ez((t - 0.40 - i * 0.035) / 0.16);
    return Transform.translate(
      offset: Offset(0, (1 - p) * sc(24)),
      child: Opacity(
        opacity: p,
        child: Text(ch,
            style: TextStyle(
                fontSize: sc(26),
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Colors.white,
                decoration: TextDecoration.none)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    return AnimatedBuilder(
      animation: _c,
      builder: (ctx, _) {
        final t = _c.value;
        final out =
            t < 0.88 ? 1.0 : (1 - (t - 0.88) / 0.12).clamp(0.0, 1.0);
        final logoIn = _ez((t - 0.16) / 0.12);
        final logoScale = 0.6 + 0.4 * _back((t - 0.16) / 0.30);
        final capP = _ez((t - 0.60) / 0.20);
        return IgnorePointer(
          child: Opacity(
            opacity: out,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFF04060A),
              child: Stack(children: [
                Positioned.fill(
                    child: CustomPaint(painter: _BootFx(t, accent))),
                Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Transform.scale(
                      scale: logoScale,
                      child: Opacity(
                        opacity: logoIn,
                        child: Container(
                          width: sc(104),
                          height: sc(104),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black,
                            border: Border.all(
                                color: accent.withOpacity(0.6),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: accent.withOpacity(0.45),
                                  blurRadius: sc(40)),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                                'assets/z2m_black_logo_256.png',
                                fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: sc(22)),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      for (var i = 0; i < _letters.length; i++)
                        _letter(i, t),
                    ]),
                    SizedBox(height: sc(10)),
                    Opacity(
                      opacity: capP,
                      child: Text(
                        widget.caption.trim().isEmpty
                            ? 'LIQUID GLASS EDITION'
                            : widget.caption.toUpperCase(),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: sc(9),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3 + 5 * (1 - capP),
                            decoration: TextDecoration.none),
                      ),
                    ),
                    SizedBox(height: sc(24)),
                    Opacity(
                      opacity: _ez((t - 0.5) / 0.15),
                      child: SizedBox(
                        width: sc(220),
                        height: sc(3),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: sc(3),
                            value: _ez((t - 0.5) / 0.42),
                            backgroundColor:
                                Colors.white.withOpacity(0.08),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(accent),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

/// ✨ кольцо, волны, капли, сканлайн, вспышка
class _BootFx extends CustomPainter {
  final double t;
  final Color accent;
  _BootFx(this.t, this.accent);

  double _cl(double x) => x.clamp(0.0, 1.0);
  double _ez(double x) {
    x = _cl(x);
    return x * x * (3 - 2 * x);
  }

  double _rnd(int i) => ((math.sin(i * 12.9898) * 43758.5453) % 1).abs();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final c = Offset(w / 2, h / 2 - sc(40));

    // 1) кольцо-развёртка вокруг логотипа
    final ringP = _ez((t - 0.02) / 0.26);
    if (ringP > 0 && t < 0.55) {
      final r = sc(64);
      final sweep = ringP * 2 * math.pi;
      final fade = 1 - _cl((t - 0.45) / 0.10);
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2,
          sweep, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..color = accent.withOpacity(0.8 * fade));
      if (ringP < 1) {
        final a = -math.pi / 2 + sweep;
        final tip = c + Offset(math.cos(a) * r, math.sin(a) * r);
        canvas.drawCircle(tip, 8, Paint()..color = accent.withOpacity(0.35));
        canvas.drawCircle(
            tip, 3.5, Paint()..color = Colors.white.withOpacity(0.9));
      }
    }

    // 2) ударные волны
    for (var k = 0; k < 2; k++) {
      final sP = _cl((t - 0.30 - k * 0.08) / 0.30);
      if (sP > 0 && sP < 1) {
        final r = sc(60) + _ez(sP) * math.max(w, h) * 0.55;
        canvas.drawCircle(c, r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = accent.withOpacity(0.35 * (1 - sP)));
      }
    }

    // 3) капли разлетаются
    for (var i = 0; i < 36; i++) {
      final ang = _rnd(i) * 2 * math.pi;
      final sp = 0.5 + _rnd(i + 7) * 0.9;
      final p = _cl((t - 0.30) / (0.5 * sp));
      if (p <= 0 || p >= 1) continue;
      final dist = _ez(p) * (sc(90) + _rnd(i + 13) * sc(160));
      final pos =
          c + Offset(math.cos(ang) * dist, math.sin(ang) * dist * 0.8);
      final alpha = (1 - p) * 0.8;
      canvas.drawCircle(pos, (1.2 + _rnd(i + 29) * 2.2) * (1 - p * 0.5),
          Paint()
            ..color =
                (i % 5 == 0 ? Colors.white : accent).withOpacity(alpha));
    }

    // 4) блик-сканлайн по экрану
    final glP = _cl((t - 0.62) / 0.22);
    if (glP > 0 && glP < 1) {
      final x = -w * 0.3 + glP * w * 1.6;
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + w * 0.18, 0)
        ..lineTo(x + w * 0.18 - h * 0.25, h)
        ..lineTo(x - h * 0.25, h)
        ..close();
      canvas.drawPath(
          path,
          Paint()
            ..shader = LinearGradient(colors: [
              Colors.white.withOpacity(0),
              Colors.white.withOpacity(0.07),
              Colors.white.withOpacity(0),
            ]).createShader(
                Rect.fromLTWH(x - h * 0.25, 0, w * 0.18 + h * 0.25, h)));
    }

    // 5) финальная вспышка
    final fl = _cl((t - 0.88) / 0.10);
    if (fl > 0) {
      canvas.drawRect(Rect.fromLTRB(0, 0, w, h),
          Paint()..color = accent.withOpacity(0.25 * fl));
    }
  }

  @override
  bool shouldRepaint(covariant _BootFx old) => old.t != t;
}