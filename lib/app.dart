import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'core/app_theme.dart';
import 'core/ui_scale.dart';
import 'core/ui_settings.dart';
import 'ui/home_page.dart';
import 'ui/settings_page.dart';
import 'ui/style/effects.dart';
import 'ui/widgets/notify_bell.dart';
import 'ui/widgets/boot_screen.dart';
import 'core/sound_service.dart';
import 'services/update_service.dart';
import 'core/notify_service.dart';

class Z2MiniApp extends StatelessWidget {
  const Z2MiniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: UiSettings.general, builder: (ctx, _) {
      UiScale.value = UiSettings.uiScale.value;
      final speed = UiSettings.animSpeed.value.clamp(0.5, 2.0);
      final dur = UiSettings.animationsEnabled.value
          ? Duration(milliseconds: (280 / speed).round())
          : Duration.zero;
      final base = (UiSettings.isDark.value ? AppTheme.dark() : AppTheme.light())
          .withAnim(dur);
      var t = UiSettings.accentColor.value == null
          ? base
          : base.withAccent(UiSettings.accentColor.value!);
      if (UiSettings.buttonColor.value != null) {
        t = t.withButton(UiSettings.buttonColor.value!);
      }
      return MaterialApp(
        title: 'Z2 Mini',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: UiSettings.fontMode.value == 1 ? 'Consolas' : null,
          scaffoldBackgroundColor: Colors.transparent,
          colorScheme: ColorScheme.fromSeed(
            seedColor: t.accent,
            brightness: UiSettings.isDark.value ? Brightness.dark : Brightness.light,
          ),
        ),
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c)
              .copyWith(textScaler: TextScaler.linear(UiScale.value)),
          child: child!,
        ),
        home: _Shell(t: t),
      );
    });
  }
}

class _Shell extends StatefulWidget {
  final AppTheme t;
  const _Shell({required this.t});
  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> with TickerProviderStateMixin {
  int _page = 0; // целевая
  int _from = 0; // откуда анимируем
  bool _switching = false;
  bool _boot = true;
  // 🔒 ключи: состояние Главной/Настроек не сбрасывается при перестройках
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();
  Timer? _autoTimer;
  final ValueNotifier<Offset> _par = ValueNotifier(Offset.zero);
  bool _dragging = false; // 🔒 пока тащим ползунок — параллакс спит

  late final AnimationController _pageCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
  );

  AppTheme get t => widget.t;

  @override
  void initState() {
    super.initState();
    if (!UiSettings.bootEnabled.value) _boot = false;
    windowManager.setAlwaysOnTop(UiSettings.alwaysOnTop.value);
    windowManager.setOpacity(UiSettings.windowOpacity.value);
    _applyAutoTheme();
    _autoTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _applyAutoTheme());
    _pageCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _switching = false);
      }
    });
    // 🔄 тихая проверка обновлений после запуска
    Future.delayed(const Duration(seconds: 4), _checkUpdates);
  }

  Future<void> _checkUpdates() async {
    final c = await UpdateService.check();
    if (c.release == null || !mounted) return; // тихо: нет обновы или ошибка
    NotifyService.push(
      'Доступно обновление ${c.release!.version} — тапни, чтобы установить',
      icon: Icons.system_update_rounded,
      soundEvent: 'update',
      onTap: () => UpdateService.startUpdate(c.release!),
    );
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageCtrl.dispose();
    _par.dispose();
    super.dispose();
  }

  void _applyAutoTheme() {
    if (!UiSettings.autoTheme.value) return;
    final h = DateTime.now().hour;
    final dark = h >= 19 || h < 7;
    if (UiSettings.isDark.value != dark) {
      UiSettings.isDark.value = dark;
      UiSettings.save();
    }
  }

  static double _easeInOutCubic(double x) {
    final p = -2 * x + 2;
    return x < 0.5 ? 4 * x * x * x : 1 - (p * p * p) / 2;
  }

  void _go(int i) {
    if (i == _page) return;
    setState(() {
      _from = _page;
      _page = i;
      _switching = true;
    });
    if (!UiSettings.animationsEnabled.value) {
      _pageCtrl.stop();
      setState(() => _switching = false);
      return;
    }
    final speed = UiSettings.animSpeed.value.clamp(0.5, 2.0);
    _pageCtrl.duration = Duration(milliseconds: (340 / speed).round());
    _pageCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _dragging = true,
      onPointerUp: (_) => _dragging = false,
      onPointerCancel: (_) => _dragging = false,
      onPointerMove: (e) {
        if (!UiSettings.parallax.value || _dragging) {
          if (_par.value != Offset.zero) _par.value = Offset.zero;
          return;
        }
        final size = MediaQuery.of(context).size;
        final target = Offset(
          e.position.dx / size.width - 0.5,
          e.position.dy / size.height - 0.5,
        );
        if ((target.dx - _par.value.dx).abs() > 0.005 ||
            (target.dy - _par.value.dy).abs() > 0.005) {
          _par.value = target;
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        child: Stack(children: [
          backgroundDecor(t.bg),
          AnimatedBuilder(animation: UiSettings.aurora, builder: (ctx, _) {
            if (!UiSettings.liveBg.value) return const SizedBox.shrink();
            return ValueListenableBuilder<Offset>(
              valueListenable: _par,
              builder: (ctx, off, _) => ValueListenableBuilder<bool>(
                valueListenable: UiSettings.parallax,
                // ⚡ нет параллакса → нет Transform: фон рисуется 1:1
              builder: (ctx, px, _) => px
                  ? Transform.translate(
                      offset: Offset(off.dx * -sc(120), off.dy * -sc(80)),
                      child: Transform.scale(
                        scale: 1.15,
                        child: LiveBackground(
                          color: UiSettings.bgColor.value ?? t.accent,
                          speed: UiSettings.auroraSpeed.value,
                          style: UiSettings.bgStyle.value,
                        ),
                      ),
                    )
                  : LiveBackground(
                      color: UiSettings.bgColor.value ?? t.accent,
                      speed: UiSettings.auroraSpeed.value,
                      style: UiSettings.bgStyle.value,
                    ),
              ),
            );
          }),
          AnimatedBuilder(
            animation: UiSettings.general,
            builder: (ctx, _) => IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(UiSettings.vignette.value),
                  ]),
                ),
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: ValueListenableBuilder<bool>(
              valueListenable: UiSettings.sidebarRight,
              builder: (ctx, right, _) => Row(children: [
                if (!right) ...[_sidebar(), _divider()],
                Expanded(child: _content()),
                if (right) ...[_divider(), _sidebar()],
              ]),
            ),
          ),
          NotifyBell(theme: t),
          if (_boot)
            BootScreen(
              durationMs: (UiSettings.bootDuration.value * 1000).round(),
              caption: UiSettings.bootCaption.value,
              onDone: () => setState(() => _boot = false),
            ),
        ]),
      ),
    );
  }

  Widget _divider() => VerticalDivider(
      width: 1,
      thickness: 1,
      color: Colors.white.withOpacity(t.isDark ? 0.10 : 0.35));

      Widget _content() => Stack(children: [
        Positioned.fill(
          child: ClipRect(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _pageCtrl,
                builder: (ctx, _) {
                  final double pos = _switching
                      ? _from +
                          (_page - _from) *
                              _easeInOutCubic(
                                  _pageCtrl.value.clamp(0.0, 1.0))
                      : _page.toDouble();
                  return Stack(children: [
                    IgnorePointer(
                      ignoring: pos > 0.5,
                      child: Opacity(
                          opacity: 1 - pos, child: HomePage(theme: t)),
                    ),
                    IgnorePointer(
                      ignoring: pos < 0.5,
                      child: Opacity(
                          opacity: pos, child: SettingsPage(theme: t)),
                    ),
                  ]);
                },
              ),
            ),
          ),
        ),
        Positioned(top: 0, left: 0, right: 0, child: _titleBar()),
      ]);

  Widget _titleBar() => GestureDetector(
        behavior: HitTestBehavior.translucent,
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
            const Spacer(),
            _WinBtn(kind: _G.min, theme: t, onPressed: () => windowManager.minimize()),
            _WinBtn(kind: _G.max, theme: t, onPressed: () async {
              if (await windowManager.isMaximized()) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            }),
            _WinBtn(
                kind: _G.close,
                theme: t,
                isClose: true,
                onPressed: () => windowManager.close()),
            SizedBox(width: sc(6)),
          ]),
        ),
      );

  Widget _sidebar() => ValueListenableBuilder<bool>(
        valueListenable: UiSettings.realBlur,
        builder: (ctx, real, _) => ClipRect(
          child: real
              ? BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: _sidebarBody(),
                )
              : _sidebarBody(),
        ),
      );

  Widget _sidebarBody() => Container(
        width: sc(84),
        color: (t.isDark ? const Color(0xFF0B0E14) : Colors.white)
            .withOpacity(t.isDark ? 0.35 : 0.5),
        child: Column(children: [
          const Spacer(),
          _item(0, Icons.home_rounded, tr('Главная', 'Home')),
          SizedBox(height: sc(14)),
          _item(1, Icons.settings_rounded, tr('Настройки', 'Settings')),
          const Spacer(),
        ]),
      );

  Widget _item(int i, IconData ic, String label) {
    final active = _page == i;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SoundService.click();
        _go(i);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: t.animDur,
          curve: t.animCurve,
          width: sc(60),
          height: sc(60),
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      t.accent.withOpacity(0.28),
                      t.accent.withOpacity(0.12),
                    ],
                  )
                : null,
            color: active ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: active ? t.accent.withOpacity(0.5) : Colors.transparent),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: t.accent.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ]
                : null,
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(ic,
                size: sc(19),
                color: active ? t.accent : t.text.withOpacity(0.55)),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: sc(9),
                    fontWeight: FontWeight.w700,
                    color: active ? t.accent : t.text.withOpacity(0.55))),
          ]),
        ),
      ),
    );
  }
}

enum _G { min, max, close }

class _WinBtn extends StatefulWidget {
  final _G kind;
  final AppTheme theme;
  final VoidCallback onPressed;
  final bool isClose;
  const _WinBtn(
      {super.key,
      required this.kind,
      required this.theme,
      required this.onPressed,
      this.isClose = false});
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
    final fg =
        widget.isClose && hovered ? Colors.white : t.text.withOpacity(0.75);
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          SoundService.click();
          widget.onPressed();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          width: sc(42),
          height: sc(30),
          margin: EdgeInsets.symmetric(horizontal: sc(2)),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(sc(9))),
          child: AnimatedScale(
            scale: hovered ? 1.12 : 1,
            duration: const Duration(milliseconds: 170),
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

class _GlyphPainter extends CustomPainter {
  final _G kind;
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
    final double w = size.width, h = size.height;
    switch (kind) {
      case _G.min:
        canvas.drawLine(Offset(w * 0.15, h * 0.5), Offset(w * 0.85, h * 0.5), p);
        break;
      case _G.max:
        final double l = w * 0.15, c = w * 0.30;
        canvas.drawLine(Offset(l, l + c), Offset(l, l), p);
        canvas.drawLine(Offset(l, l), Offset(l + c, l), p);
        canvas.drawLine(Offset(w - l - c, l), Offset(w - l, l), p);
        canvas.drawLine(Offset(w - l, l), Offset(w - l, l + c), p);
        canvas.drawLine(Offset(w - l, h - l - c), Offset(w - l, h - l), p);
        canvas.drawLine(Offset(w - l, h - l), Offset(w - l - c, h - l), p);
        canvas.drawLine(Offset(l + c, h - l), Offset(l, h - l), p);
        canvas.drawLine(Offset(l, h - l), Offset(l, h - l - c), p);
        break;
      case _G.close:
        canvas.drawLine(Offset(w * 0.22, h * 0.22), Offset(w * 0.78, h * 0.78), p);
        canvas.drawLine(Offset(w * 0.78, h * 0.22), Offset(w * 0.22, h * 0.78), p);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) =>
      old.color != color || old.kind != kind;
}