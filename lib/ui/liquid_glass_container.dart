import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/ui_scale.dart';
import '../core/ui_settings.dart';

class LiquidGlassContainer extends StatelessWidget {
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
    final outer = ui.ColorFilter.matrix(<double>[
      0.213 + 0.787 * s, 0.715 - 0.715 * s, 0.072 - 0.072 * s, 0, 0,
      0.213 - 0.213 * s, 0.715 + 0.285 * s, 0.072 - 0.072 * s, 0, 0,
      0.213 - 0.213 * s, 0.715 - 0.715 * s, 0.072 + 0.928 * s, 0, 0,
      0, 0, 0, 1, 0,
    ]);
    return ui.ImageFilter.compose(outer: outer, inner: inner);
  }

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return AnimatedBuilder(
      animation: UiSettings.glass,
      builder: (ctx, _) {
        final blur = UiSettings.blurSigma.value;
        final sat = UiSettings.saturation.value;
        final op = UiSettings.glassOpacity.value;
        final glow = UiSettings.edgeGlow.value;
        final border = UiSettings.borderOpacity.value;
        final spec = UiSettings.specular.value;
        final rad = UiSettings.glassRadius.value;
        final tint = UiSettings.glassTint.value;
        final r = radius >= 999 ? radius : rad;

        final deco = BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          border: Border.all(
              color: Colors.white.withOpacity(t.isDark ? border : border * 1.8),
              width: 1),
          boxShadow: (UiSettings.cardShadows.value && !UiSettings.ecoMode.value)
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(t.isDark ? 0.35 : 0.10),
                      blurRadius: 30,
                      offset: const Offset(0, 12)),
                  if (glow > 0.01)
                    BoxShadow(
                        color: tint.withOpacity(glow * 0.35), blurRadius: 26),
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
          Padding(padding: padding ?? EdgeInsets.all(sc(14)), child: child),
        ]);

        // 🪶 Настоящий BackdropFilter ТОЛЬКО если включён тумблер.
        // Иначе лёгкие слои: визуально то же, но GPU не реблюрит каждый кадр.
        return ValueListenableBuilder<bool>(
          valueListenable: UiSettings.realBlur,
          builder: (ctx, real, _) => ClipRRect(
            borderRadius: BorderRadius.circular(r),
            child: real
                ? BackdropFilter(
                    filter: _filter(blur, sat),
                    child: Container(decoration: deco, child: inner),
                  )
                : Container(decoration: deco, child: inner),
          ),
        );
      },
    );
  }
}