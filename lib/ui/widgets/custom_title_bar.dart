import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/app_theme.dart';
import '../../core/ui_scale.dart';

/// 🪟 Тайтл-бар Z2 Mini: глифы нарисованы вручную (CustomPaint),
/// никаких стандартных иконок Windows/Material.
class MiniTitleBar extends StatelessWidget {
  final AppTheme theme;
  const MiniTitleBar({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: () async {
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
      },
      child: SizedBox(
        height: sc(40),
        child: Row(children: [
          SizedBox(width: sc(14)),
          // светящаяся точка-лого
          Container(
            width: sc(9),
            height: sc(9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [t.accent.withOpacity(0.95), t.accent.withOpacity(0.45)],
              ),
              boxShadow: [BoxShadow(color: t.accent.withOpacity(0.45), blurRadius: sc(8))],
            ),
          ),
          SizedBox(width: sc(8)),
          Text('Z2 Mini',
              style: TextStyle(
                  fontSize: sc(11),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: t.text.withOpacity(0.85))),
          const Spacer(),
          _WinBtn(kind: _GlyphKind.min, theme: t, onPressed: () => windowManager.minimize()),
          _WinBtn(kind: _GlyphKind.max, theme: t, onPressed: () async {
            if (await windowManager.isMaximized()) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          }),
          _WinBtn(kind: _GlyphKind.close, theme: t, isClose: true,
              onPressed: () => windowManager.close()),
          SizedBox(width: sc(6)),
        ]),
      ),
    );
  }
}

enum _GlyphKind { min, max, close }

class _WinBtn extends StatefulWidget {
  final _GlyphKind kind;
  final AppTheme theme;
  final VoidCallback onPressed;
  final bool isClose;
  const _WinBtn({
    required this.kind,
    required this.theme,
    required this.onPressed,
    this.isClose = false,
  });
  @override
  State<_WinBtn> createState() => _WinBtnState();
}

class _WinBtnState extends State<_WinBtn> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final bg = widget.isClose && hovered
        ? const Color(0xFFEF4444)
        : (hovered ? t.text.withOpacity(0.08) : Colors.transparent);
    final fg = widget.isClose && hovered ? Colors.white : t.text.withOpacity(0.75);
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          width: sc(42),
          height: sc(30),
          margin: EdgeInsets.symmetric(horizontal: sc(2)),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(sc(9)),
          ),
          child: AnimatedScale(
            scale: hovered ? 1.12 : 1,
            duration: const Duration(milliseconds: 160),
            child: Center(
              child: CustomPaint(
                size: Size(sc(12), sc(12)),
                painter: _GlyphPainter(kind: widget.kind, color: fg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ✍️ альтернативные глифы: черта / уголки-рамка / крест — круглые штрихи
class _GlyphPainter extends CustomPainter {
  final _GlyphKind kind;
  final Color color;
  _GlyphPainter({required this.kind, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width, h = size.height;
    switch (kind) {
      case _GlyphKind.min:
        // минимизация: короткая черта
        canvas.drawLine(Offset(w * 0.15, h * 0.5), Offset(w * 0.85, h * 0.5), p);
        break;
      case _GlyphKind.max:
        // развёрнуть: четыре уголка-рамки (вместо обычного квадрата)
        final l = w * 0.15;
        final c = w * 0.30;
        // ↖
        canvas.drawLine(Offset(l, l + c), Offset(l, l), p);
        canvas.drawLine(Offset(l, l), Offset(l + c, l), p);
        // ↗
        canvas.drawLine(Offset(w - l - c, l), Offset(w - l, l), p);
        canvas.drawLine(Offset(w - l, l), Offset(w - l, l + c), p);
        // ↘
        canvas.drawLine(Offset(w - l, h - l - c), Offset(w - l, h - l), p);
        canvas.drawLine(Offset(w - l, h - l), Offset(w - l - c, h - l), p);
        // ↙
        canvas.drawLine(Offset(l + c, h - l), Offset(l, h - l), p);
        canvas.drawLine(Offset(l, h - l), Offset(l, h - l - c), p);
        break;
      case _GlyphKind.close:
        canvas.drawLine(Offset(w * 0.22, h * 0.22), Offset(w * 0.78, h * 0.78), p);
        canvas.drawLine(Offset(w * 0.78, h * 0.22), Offset(w * 0.22, h * 0.78), p);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) =>
      old.color != color || old.kind != kind;
}