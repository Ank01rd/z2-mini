import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/ui_scale.dart';
import '../../core/ui_settings.dart';

/// ⚫⚪ NothingOS-style boot: dot-matrix «Z2 MINI», dotted-прогресс,
/// красная мигающая точка, моно-подпись. ~2.6 сек, затем фейд.
class BootScreen extends StatefulWidget {
  final VoidCallback onDone;
  final int durationMs;
  final String caption;
  const BootScreen({super.key, required this.onDone, this.durationMs = 3500, this.caption = ''});
  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: Duration(milliseconds: widget.durationMs));

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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (ctx, _) {
        final t = _c.value;
        final out =
            t < 0.86 ? 1.0 : (1 - (t - 0.86) / 0.14).clamp(0.0, 1.0);
        return IgnorePointer(
          child: Opacity(
            opacity: out,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFF000000),
              child: Column(children: [
                const Spacer(),
                CustomPaint(
                    size: Size(sc(470), sc(80)),
                    painter: _DotTextPainter(t)),
                SizedBox(height: sc(20)),
                CustomPaint(
                    size: Size(sc(240), sc(8)),
                    painter: _ProgressPainter(t)),
                SizedBox(height: sc(14)),
                                Opacity(
                  opacity: ((t - 0.45) / 0.2).clamp(0.0, 1.0),
                  child: Text(
                      widget.caption.trim().isEmpty
                          ? 'L I Q U I D   G L A S S   E D I T I O N'
                          : widget.caption.toUpperCase(),
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: sc(9),
                          fontFamily: 'monospace',
                          letterSpacing: 2,
                          decoration: TextDecoration.none)),
                ),
                const Spacer(),
              ]),
            ),
          ),
        );
      },
    );
  }
}

/// dot-matrix текст «Z2 MINI»: точки-«пиксели» вспыхивают волной слева направо
class _DotTextPainter extends CustomPainter {
  final double t;
  _DotTextPainter(this.t);

  static const Map<String, List<String>> _font = {
    'Z': ['11111', '00010', '00100', '01000', '11111'],
    '2': ['11110', '00001', '01110', '10000', '11111'],
    'M': ['10001', '11011', '10101', '10001', '10001'],
    'I': ['11111', '00100', '00100', '00100', '11111'],
    'N': ['10001', '11001', '10101', '10011', '10001'],
    ' ': ['00', '00', '00', '00', '00'],
  };

  @override
  void paint(Canvas canvas, Size size) {
    const text = 'Z2 MINI';
    final List<List<int>> cols = [];
    for (final ch in text.split('')) {
      final g = _font[ch]!;
      for (var x = 0; x < g[0].length; x++) {
        cols.add([for (var y = 0; y < 5; y++) int.parse(g[y][x])]);
      }
      cols.add([0, 0, 0, 0, 0]); // межбуквенный зазор
    }
    final cellW = size.width / cols.length;
    final cellH = size.height / 5;
    final r = math.min(cellW, cellH) * 0.30;
    var ci = 0;
    for (final col in cols) {
      for (var y = 0; y < 5; y++) {
        final cx = ci * cellW + cellW / 2;
        final cy = y * cellH + cellH / 2;
        // «негорящая» точка матрицы — как у Nothing
        canvas.drawCircle(Offset(cx, cy), r * 0.8,
            Paint()..color = const Color(0xFFFFFFFF).withOpacity(0.07));
        if (col[y] == 1) {
          final d = 0.06 +
              (ci / cols.length) * 0.40 +
              _rnd(ci * 7 + y * 13) * 0.18;
          final a = _smooth(((t - d) / 0.12).clamp(0.0, 1.0));
          if (a > 0) {
            canvas.drawCircle(
                Offset(cx, cy),
                r * (0.4 + 0.6 * a),
                Paint()
                  ..color = const Color(0xFFFFFFFF).withOpacity(a));
          }
        }
      }
      ci++;
    }
    // 🔴 фирменная красная мигающая точка-курсор
    if (t > 0.55) {
      final blink = (t * 6) % 1 < 0.6 ? 1.0 : 0.15;
      canvas.drawCircle(
          Offset(size.width - cellW, size.height / 2),
          r * 1.1,
          Paint()
            ..color = const Color(0xFFD71921).withOpacity(blink));
    }
  }

  double _rnd(int i) => ((math.sin(i * 12.9898) * 43758.5453) % 1).abs();
  double _smooth(double x) => x * x * (3 - 2 * x);

  @override
  bool shouldRepaint(covariant _DotTextPainter old) => old.t != t;
}

/// dotted-прогресс: точки заполняются слева направо
class _ProgressPainter extends CustomPainter {
  final double t;
  _ProgressPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 26;
    final p = ((t - 0.5) / 0.32).clamp(0.0, 1.0);
    final step = size.width / n;
    for (var i = 0; i < n; i++) {
      final on = i / n < p;
      canvas.drawCircle(
          Offset(i * step + step / 2, size.height / 2),
          step * 0.22,
          Paint()
            ..color = const Color(0xFFFFFFFF).withOpacity(on ? 0.9 : 0.12));
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter old) => old.t != t;
}