import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/ui_scale.dart';
import '../core/ui_settings.dart';

class LiquidGlassContainer extends StatefulWidget {
  final AppTheme theme;
  final Widget child;
  final double radius;
  final EdgeInsets? padding;
  const LiquidGlassContainer(
      {super.key,
      required this.theme,
      required this.child,
      this.radius = 24,
      this.padding});

  static ui.ImageFilter _filter(double blur, double s) {
    final inner = ui.ImageFilter.blur(
        sigmaX: blur, sigmaY: blur, tileMode: TileMode.clamp);
    if (s <= 1.001) return inner;
    final outer = ui.ImageFilter.compose(
        outer: ui.ColorFilter.matrix(<double>[
          0.213 + 0.787 * s, 0.715 - 0.715 * s, 0.072 - 0.072 * s, 0, 0,
          0.213 - 0.213 * s, 0.715 + 0.285 * s, 0.072 - 0.072 * s, 0, 0,
          0.213 - 0.213 * s, 0.715 - 0.715 * s, 0.072 + 0.928 * s, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        inner: inner);
    return outer;
  }

  @override
  State<LiquidGlassContainer> createState() => _LiquidGlassContainerState();
}

class _LiquidGlassContainerState extends State<LiquidGlassContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
  bool _hover = false;

  void _onEnter() {
    _hover = true;
    if (UiSettings.sweepFx.value) _sweep.forward(from: 0);
  }

  void _onExit() => _hover = false;

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return AnimatedBuilder(
      animation: Listenable.merge([UiSettings.glass, _sweep]),
      builder: (ctx, _) {
        final blur = UiSettings.blurSigma.value;
        final sat = UiSettings.saturation.value;
        final op = UiSettings.glassOpacity.value;
        final glow = UiSettings.edgeGlow.value;
        final border = UiSettings.borderOpacity.value;
        final spec = UiSettings.specular.value;
        final rad = UiSettings.glassRadius.value;
        final tint = UiSettings.glassTint.value;
        final r = widget.radius >= 999 ? widget.radius : rad;

        final deco = BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          border: Border.all(
              color:
                  Colors.white.withOpacity(t.isDark ? border : border * 1.8),
              width: 1),
          boxShadow:
              (UiSettings.cardShadows.value && !UiSettings.ecoMode.value)
                  ? [
                      BoxShadow(
                          color: Colors.black
                              .withOpacity(t.isDark ? 0.35 : 0.10),
                          blurRadius: 30,
                          offset: const Offset(0, 12)),
                      if (glow > 0.01)
                        BoxShadow(
                            color: tint.withOpacity(glow * 0.35),
                            blurRadius: 26),
                    ]
                  : null,
        );

        final inner = Stack(children: [
          Positioned.fill(
              child: Container(
                  color: (t.isDark ? const Color(0xFF0B0E14) : Colors.white)
                      .withOpacity(op))),
          Positioned.fill(
              child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                Colors.white.withOpacity(0.08 + glow * 0.10),
                tint.withOpacity(0.10),
                Colors.black.withOpacity(t.isDark ? 0.05 : 0.02),
              ])))),
          if (spec > 0.01)
            Positioned(
                left: r * 0.7,
                right: r * 0.7,
                top: 0,
                height: 1.3,
                child: IgnorePointer(
                    child: Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                  Colors.white.withOpacity(0),
                  Colors.white.withOpacity(spec),
                  Colors.white.withOpacity(0),
                ]))))),
          Padding(
              padding: widget.padding ?? EdgeInsets.all(sc(14)),
              child: widget.child),
        ]);

        return ValueListenableBuilder<bool>(
          valueListenable: UiSettings.realBlur,
          builder: (ctx, real, _) => MouseRegion(
            onEnter: (_) => _onEnter(),
            onExit: (_) => _onExit(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(r),
              child: Stack(children: [
                real
                    ? BackdropFilter(
                        filter: LiquidGlassContainer._filter(blur, sat),
                        child: Container(decoration: deco, child: inner),
                      )
                    : Container(decoration: deco, child: inner),
                // 💫 свип-блик при наведении — теперь заметный
                if (UiSettings.sweepFx.value)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                          painter: _SweepPainter(_sweep.value)),
                    ),
                  ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

/// 💫 широкая световая полоса с ярким ядром
class _SweepPainter extends CustomPainter {
  final double v;
  _SweepPainter(this.v);
  @override
  void paint(Canvas canvas, Size size) {
    if (v <= 0 || v >= 1) return;
    final w = size.width, h = size.height;
    final bw = w * 0.35;
    final x = -bw + (w + bw * 2) * v;
    final skew = h * 0.25;
    final path = Path()
      ..moveTo(x, -4)
      ..lineTo(x + bw, -4)
      ..lineTo(x + bw - skew, h + 4)
      ..lineTo(x - skew, h + 4)
      ..close();
    final fade = v < 0.15 ? v / 0.15 : (v > 0.8 ? (1 - v) / 0.2 : 1.0);
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(Offset(x - skew, 0), Offset(x + bw, 0), [
          Colors.white.withOpacity(0),
          Colors.white.withOpacity(0.12 * fade),
          Colors.white.withOpacity(0.26 * fade),
          Colors.white.withOpacity(0.12 * fade),
          Colors.white.withOpacity(0),
        ]),
    );
  }

  @override
  bool shouldRepaint(covariant _SweepPainter o) => o.v != v;
}