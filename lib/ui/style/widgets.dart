import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/ui_scale.dart';
import '../../core/ui_settings.dart';
import '../../core/sound_service.dart';
import '../../core/notify_service.dart';

// ✨ каскадное появление карточек
class AnimatedReveal extends StatefulWidget {
  final Widget child;
  final int i;
  const AnimatedReveal({super.key, required this.child, this.i = 0});
  @override
  State<AnimatedReveal> createState() => _AnimatedRevealState();
}

class _AnimatedRevealState extends State<AnimatedReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 540));
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: (widget.i % 24) * 60), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cur = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return FadeTransition(opacity: cur,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(cur),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(cur),
          child: widget.child)));
  }
}

// 🔘 2.5D-кнопка с мягкими тенями (из оригинала)
class Btn25D extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final Color base;
  final EdgeInsets padding;
  const Btn25D({super.key, required this.child, this.onTap, this.radius = 14,
    required this.base, this.padding = const EdgeInsets.all(10)});
  @override
  State<Btn25D> createState() => _Btn25DState();
}

class _Btn25DState extends State<Btn25D> {
  bool hovered = false, pressed = false;
  @override
  Widget build(BuildContext context) {
    final s = UiScale.value;
    final r = widget.radius >= 999 ? widget.radius : widget.radius * s;
        final _g2 = UiSettings.gradientAccent.value
        ? Color.lerp(widget.base,
            UiSettings.accent2.value ?? const Color(0xFF22D3EE), 0.7)!
        : widget.base;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => pressed = true),
        onTapUp: (_) => setState(() => pressed = false),
        onTapCancel: () => setState(() => pressed = false),
        onTap: () {
          SoundService.click();
          widget.onTap?.call();
        },
        child: AnimatedScale(
          scale: pressed ? 0.97 : (hovered ? 1.02 : 1),
          duration: const Duration(milliseconds: 170),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: widget.padding.scaleBy(s),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: pressed
                    ? [widget.base.withOpacity(0.55), _g2.withOpacity(0.75)]
                    : [widget.base.withOpacity(0.95), _g2.withOpacity(0.65)]),
              borderRadius: BorderRadius.circular(r),
              border: Border.all(
                  color: Colors.white.withOpacity(pressed ? 0.05 : (hovered ? 0.28 : 0.14))),
                boxShadow: (pressed || !UiSettings.cardShadows.value || UiSettings.ecoMode.value) ? [] : [
                BoxShadow(color: Colors.black.withOpacity(0.22),
                    blurRadius: hovered ? 9 : 5, offset: Offset(0, hovered ? 3 : 2)),
                BoxShadow(color: Colors.white.withOpacity(0.05), blurRadius: 1,
                    offset: const Offset(0, -1)),
              ]),
            child: widget.child))),
    );
  }
}

// ⭕ анимированное радио (из оригинала)
class FilterRadio extends StatefulWidget {
  final String label;
  final bool selected;
  final AppTheme theme;
  final VoidCallback onTap;
  const FilterRadio({super.key, required this.label, required this.selected,
    required this.theme, required this.onTap});
  @override
  State<FilterRadio> createState() => _FilterRadioState();
}

class _FilterRadioState extends State<FilterRadio> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    final t = widget.theme, sel = widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: t.animDur, curve: t.animCurve,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsets.symmetric(horizontal: sc(9), vertical: sc(5)),
          decoration: BoxDecoration(
            color: sel ? t.accent.withOpacity(hovered ? 0.20 : 0.13)
                : (hovered ? Colors.white.withOpacity(t.isDark ? 0.06 : 0.35) : Colors.transparent),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: sel ? t.accent.withOpacity(0.55)
                  : Colors.white.withOpacity(hovered ? (t.isDark ? 0.18 : 0.5) : 0)),
          ),
          child: Row(children: [
            AnimatedContainer(duration: t.animDur, curve: t.animCurve,
              width: sc(16), height: sc(16),
              decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(
                    color: sel ? t.accent : t.text.withOpacity(hovered ? 0.55 : 0.35),
                    width: sel ? 1.6 : 1.4),
                boxShadow: sel ? [BoxShadow(color: t.accent.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 2))] : null),
              child: Center(child: AnimatedScale(scale: sel ? 1 : 0,
                duration: const Duration(milliseconds: 400), curve: Curves.easeOutBack,
                child: Container(width: sc(8), height: sc(8),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: t.accent))))),
            SizedBox(width: sc(8)),
                  Expanded(
        child: AnimatedDefaultTextStyle(duration: const Duration(milliseconds: 280),
          style: TextStyle(fontSize: sc(12),
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            color: sel ? t.text : t.text.withOpacity(0.7)),
          child: Text(widget.label, overflow: TextOverflow.ellipsis)),
      ),
          ]))));
  }
}

// 🔔 тосты
class _ToastData { final int id; final String text; final IconData icon; bool show;
  _ToastData({required this.id, required this.text, required this.icon, this.show = false}); }

class ToastService {
  static final ValueNotifier<List<_ToastData>> toasts = ValueNotifier([]);
  static int _nextId = 0;

  static void show(String text, IconData icon) {
    NotifyService.push(text, icon: icon);
    final d = _ToastData(id: _nextId++, text: text, icon: icon);
    final list = [...toasts.value, d];
    if (list.length > 4) list.removeAt(0);
    toasts.value = list;
    Future.delayed(const Duration(milliseconds: 30), () {
      d.show = true;
      toasts.value = [...toasts.value];
    });
    Timer(const Duration(milliseconds: 2600), () => _dismiss(d));
  }

  static void _dismiss(_ToastData d) {
    if (!toasts.value.any((x) => x.id == d.id)) return;
    d.show = false;
    toasts.value = [...toasts.value];
    Timer(const Duration(milliseconds: 450), () {
      toasts.value = toasts.value.where((x) => x.id != d.id).toList();
    });
  }
}

class ToastOverlay extends StatelessWidget {
  final AppTheme theme;
  const ToastOverlay({super.key, required this.theme});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<_ToastData>>(
      valueListenable: ToastService.toasts,
      builder: (ctx, list, _) => Positioned(top: sc(10), left: 0, right: 0,
        child: IgnorePointer(child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < list.length; i++) ...[
            if (i > 0) SizedBox(height: sc(8)),
            _ToastPill(data: list[i]),
          ]]))));
  }
}

class _ToastPill extends StatelessWidget {
  final _ToastData data;
  const _ToastPill({super.key, required this.data});
  @override
  Widget build(BuildContext context) => Center(
    child: AnimatedScale(scale: data.show ? 1 : 0.1, alignment: Alignment.topCenter,
      duration: const Duration(milliseconds: 540),
      curve: data.show ? Curves.easeOutBack : Curves.easeInCubic,
      child: AnimatedOpacity(opacity: data.show ? 1 : 0,
        duration: Duration(milliseconds: data.show ? 120 : 200),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: sc(16), vertical: sc(10)),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.88),
            borderRadius: BorderRadius.circular(sc(30)),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: sc(16), offset: Offset(0, sc(6)))]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(data.icon, color: Colors.white, size: sc(18)),
            SizedBox(width: sc(8)),
            Flexible(child: Text(data.text, style: TextStyle(color: Colors.white,
                fontSize: sc(13), fontWeight: FontWeight.w600))),
          ])))));
}