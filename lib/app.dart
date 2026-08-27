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
            brightness: UiSettings.isDark.value
                ? Brightness.dark
                : Brightness.light,
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

class _ShellState extends State<_Shell>
    with TickerProviderStateMixin, WindowListener {
  int _page = 0;
  bool _boot = true;
  Timer? _autoTimer;
  final ValueNotifier<Offset> _par = ValueNotifier(Offset.zero);
  bool _dragging = false;
  int _dir = 1;

  final ValueNotifier<int> _settingsCat = ValueNotifier(0);

  static const List<List<Object>> _settingsCats = [
    [Icons.brush_rounded, 'Внешний вид', 'Appearance'],
    [Icons.dashboard_customize_rounded, 'Интерфейс', 'Interface'],
    [Icons.water_drop_rounded, 'Стекло', 'Glass'],
    [Icons.auto_awesome_rounded, 'Свечение', 'Glow'],
    [Icons.graphic_eq_rounded, 'Звук', 'Sound'],
    [Icons.landscape_rounded, 'Фон', 'Background'],
    [Icons.monitor_rounded, 'Графика', 'Graphics'],
    [Icons.info_rounded, 'О программе', 'About'],
  ];

  AppTheme get t => widget.t;

  Widget backgroundDecor(Color c) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              c.withOpacity(0.08),
              Colors.transparent,
              c.withOpacity(0.05),
            ],
          ),
        ),
      );

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    if (!UiSettings.bootEnabled.value) _boot = false;
    windowManager.setAlwaysOnTop(UiSettings.alwaysOnTop.value);
    windowManager.setOpacity(UiSettings.windowOpacity.value);
    _applyAutoTheme();
    _autoTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _applyAutoTheme());
    Future.delayed(const Duration(seconds: 4), _checkUpdates);
    Future.delayed(const Duration(seconds: 4), _showFinalNotice);
  }

  Future<void> _checkUpdates() async {
    final c = await UpdateService.check();
    if (c.release == null || !mounted) return;
    NotifyService.push(
      'Доступно обновление ${c.release!.version} — тапни, чтобы установить',
      icon: Icons.system_update_rounded,
      soundEvent: 'update',
      onTap: () => UpdateService.startUpdate(c.release!),
    );
  }

    // 🏁 разовое сообщение: это последний крупный билд
  void _showFinalNotice() {
    if (!mounted || UiSettings.finalNoticeShown.value) return;
    showDialog(context: context, builder: (c) => const _FinalBuildDialog())
        .then((_) {
      UiSettings.finalNoticeShown.value = true;
      UiSettings.save();
    });
  }


  @override
  void dispose() {
    windowManager.removeListener(this);
    _autoTimer?.cancel();
    _par.dispose();
    super.dispose();
  }

  // 💤 AFK: фокус/сворачивание → флаг, фон сам остановится
  @override
  void onWindowFocus() => UiSettings.windowFocused.value = true;
  @override
  void onWindowBlur() => UiSettings.windowFocused.value = false;
  @override
  void onWindowMinimize() => UiSettings.windowFocused.value = false;
  @override
  void onWindowRestore() => UiSettings.windowFocused.value = true;
  @override
  void onWindowMaximize() => UiSettings.windowFocused.value = true;
  @override
  void onWindowUnmaximize() => UiSettings.windowFocused.value = true;

  void _applyAutoTheme() {
    if (!UiSettings.autoTheme.value) return;
    final now = DateTime.now();
    final m = now.hour * 60 + now.minute;
    final from = UiSettings.themeFrom.value;
    final to = UiSettings.themeTo.value;
    final dark = from <= to ? (m >= from && m < to) : (m >= from || m < to);
    if (UiSettings.isDark.value != dark) {
      UiSettings.isDark.value = dark;
      UiSettings.save();
    }
  }

  void _go(int i) {
    if (i == _page) return;
    setState(() {
      _dir = i > _page ? 1 : -1;
      _page = i;
    });
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
                builder: (ctx, px, _) => px
                    ? Transform.translate(
                        offset: Offset(off.dx * -sc(120), off.dy * -sc(80)),
                        child: Transform.scale(
                          scale: 1.15,
                          child: LiveBackground(
                            color: UiSettings.bgColor.value ?? t.accent,
                            speed: UiSettings.auroraSpeed.value,
                            style: UiSettings.bgStyle.value,
                            density: UiSettings.bgDensity.value,
                          ),
                        ),
                      )
                    : LiveBackground(
                        color: UiSettings.bgColor.value ?? t.accent,
                        speed: UiSettings.auroraSpeed.value,
                        style: UiSettings.bgStyle.value,
                        density: UiSettings.bgDensity.value,
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
            body: ValueListenableBuilder<int>(
              valueListenable: UiSettings.sidebarPos,
              builder: (ctx, pos, _) {
                final sb = _sidebar();
                final content = Expanded(child: _content());
                switch (pos) {
                  case 1:
                    return Row(children: [content, _divider(), sb]);
                  case 2:
                    return Column(children: [sb, _dividerH(), content]);
                  case 3:
                    return Column(children: [content, _dividerH(), sb]);
                  default:
                    return Row(children: [sb, _divider(), content]);
                }
              },
            ),
          ),
          NotifyBell(theme: t, sidebarPos: UiSettings.sidebarPos),
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

  Widget _dividerH() => Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withOpacity(t.isDark ? 0.10 : 0.35));

  Widget _content() => Stack(children: [
        Positioned.fill(
          child: ClipRect(
            child: RepaintBoundary(
              child: AnimatedSwitcher(
                duration: UiSettings.animationsEnabled.value
                    ? Duration(
                        milliseconds:
                            (300 / UiSettings.animSpeed.value.clamp(0.5, 2.0))
                                .round())
                    : Duration.zero,
                transitionBuilder: (child, anim) {
                  final cur = CurvedAnimation(
                      parent: anim, curve: Curves.easeOutCubic);
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, 0.08 * _dir),
                      end: Offset.zero,
                    ).animate(cur),
                    child: FadeTransition(opacity: cur, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_page),
                  child: _page == 0
                      ? HomePage(theme: t)
                      : SettingsPage(theme: t, externalCat: _settingsCat),
                ),
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
            _WinBtn(
                kind: _G.min,
                theme: t,
                onPressed: () => windowManager.minimize()),
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

  Widget _sidebar() => ValueListenableBuilder<int>(
        valueListenable: UiSettings.sidebarPos,
        builder: (ctx, pos, _) {
          final hz = pos == 2 || pos == 3;
          return ValueListenableBuilder<bool>(
            valueListenable: UiSettings.realBlur,
            builder: (ctx, real, _) => ClipRect(
              child: real
                  ? BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: _sidebarBody(hz),
                    )
                  : _sidebarBody(hz),
            ),
          );
        },
      );

      Widget _sidebarBody(bool hz) => ValueListenableBuilder<bool>(
        valueListenable: UiSettings.compactSidebar,
        builder: (ctx, compact, _) {
          final thick = compact ? sc(56) : sc(84);
          final item = compact ? sc(40) : sc(60);
          final gap = sc(14);
          final onSettings = _page == 1;

          // 🎯 СВЕРХУ/СНИЗУ + настройки → ОДНА центрированная лента [←][категории]
          if (hz && onSettings) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              height: thick,
              color: (t.isDark ? const Color(0xFF0B0E14) : Colors.white)
                  .withOpacity(t.isDark ? 0.35 : 0.5),
              child: LayoutBuilder(
                builder: (ctx, c) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: c.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _backChip(compact),
                        for (var i = 0; i < _settingsCats.length; i++) ...[
                          SizedBox(width: sc(6)),
                          _catChip(i, compact),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          // 🧭 иначе — две кнопки Главная/Настройки с пилюлей
          final items = <Widget>[
            _item(0, Icons.home_rounded, tr('Главная', 'Home'), compact),
            SizedBox(width: gap, height: gap),
            _item(1, Icons.settings_rounded, tr('Настройки', 'Settings'),
                compact),
          ];
          final stack = SizedBox(
            width: hz ? item * 2 + gap : null,
            height: hz ? null : item * 2 + gap,
            child: Stack(children: [
              AnimatedPositioned(
                duration: t.animDur,
                curve: t.animCurve,
                top: hz ? 0 : (_page == 0 ? 0 : item + gap),
                left: hz ? (_page == 0 ? 0 : item + gap) : 0,
                right: hz ? null : 0,
                child: Center(
                  child: Container(
                    width: item,
                    height: item,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: hz ? Alignment.centerLeft : Alignment.topLeft,
                        end:
                            hz ? Alignment.centerRight : Alignment.bottomRight,
                        colors: [
                          t.accent.withOpacity(0.28),
                          t.accent.withOpacity(0.12),
                        ],
                      ),
                      border: Border.all(color: t.accent.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                            color: t.accent.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                  ),
                ),
              ),
              hz
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: items)
                  : Column(children: items),
            ]),
          );
          return AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: hz ? double.infinity : thick,
            height: hz ? thick : double.infinity,
            color: (t.isDark ? const Color(0xFF0B0E14) : Colors.white)
                .withOpacity(t.isDark ? 0.35 : 0.5),
            child: hz
                ? Row(children: [const Spacer(), stack, const Spacer()])
                : Column(children: [const Spacer(), stack, const Spacer()]),
          );
        },
      );

    // 🔙 стрелка-назад в стиле обычного чипа
  Widget _backChip(bool compact) {
    final chip = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SoundService.click();
        _go(0);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: t.animDur,
          curve: t.animCurve,
          padding: compact
              ? EdgeInsets.all(sc(9))
              : EdgeInsets.symmetric(horizontal: sc(10), vertical: sc(8)),
          decoration: BoxDecoration(
            color: t.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.accent.withOpacity(0.4)),
          ),
          child: Icon(Icons.arrow_back_rounded,
              size: sc(15), color: t.accent),
        ),
      ),
    );
    return compact
        ? Tooltip(
            message: tr('Назад', 'Back'),
            preferBelow: false,
            waitDuration: const Duration(milliseconds: 350),
            child: chip,
          )
        : chip;
  }

  // 🏷 чип категории — уважает компактный режим
  Widget _catChip(int i, bool compact) {
    final e = _settingsCats[i];
    return ValueListenableBuilder<int>(
      valueListenable: _settingsCat,
      builder: (ctx, cur, _) {
        final active = cur == i;
        final chip = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            SoundService.click();
            _settingsCat.value = i;
          },
          child: AnimatedContainer(
            duration: t.animDur,
            curve: t.animCurve,
            padding: compact
                ? EdgeInsets.all(sc(9))
                : EdgeInsets.symmetric(horizontal: sc(10), vertical: sc(8)),
            decoration: BoxDecoration(
              color: active ? t.accent.withOpacity(0.8) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: active ? t.accent : t.text.withOpacity(0.15)),
            ),
            child: compact
                ? Icon(e[0] as IconData,
                    size: sc(15),
                    color: active
                        ? t.buttonTextColor
                        : t.text.withOpacity(0.6))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(e[0] as IconData,
                        size: sc(14),
                        color: active
                            ? t.buttonTextColor
                            : t.text.withOpacity(0.6)),
                    SizedBox(width: sc(6)),
                    Text(tr(e[1] as String, e[2] as String),
                        style: TextStyle(
                            fontSize: sc(10),
                            fontWeight: FontWeight.w700,
                            color: active
                                ? t.buttonTextColor
                                : t.text.withOpacity(0.7))),
                  ]),
          ),
        );
        return compact
            ? Tooltip(
                message: tr(e[1] as String, e[2] as String),
                preferBelow: false,
                waitDuration: const Duration(milliseconds: 350),
                child: chip,
              )
            : chip;
      },
    );
  }

  Widget _backButton(bool compact) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SoundService.click();
        _go(0);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: t.animDur,
          curve: t.animCurve,
          width: compact ? sc(40) : sc(60),
          height: compact ? sc(40) : sc(60),
          decoration: BoxDecoration(
            color: t.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.accent.withOpacity(0.4)),
          ),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back_rounded,
                    size: sc(compact ? 17 : 19), color: t.accent),
                if (!compact) ...[
                  const SizedBox(height: 3),
                  Text(tr('Назад', 'Back'),
                      style: TextStyle(
                          fontSize: sc(9),
                          fontWeight: FontWeight.w700,
                          color: t.accent)),
                ],
              ]),
        ),
      ),
    );
  }

  Widget _item(int i, IconData ic, String label, bool compact) {
    final active = _page == i;
    final btn = GestureDetector(
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
          width: compact ? sc(40) : sc(60),
          height: compact ? sc(40) : sc(60),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(ic,
                size: sc(compact ? 17 : 19),
                color: active ? t.accent : t.text.withOpacity(0.55)),
            if (!compact) ...[
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                      fontSize: sc(9),
                      fontWeight: FontWeight.w700,
                      color: active ? t.accent : t.text.withOpacity(0.55))),
            ],
          ]),
        ),
      ),
    );
    return compact
        ? Tooltip(
            message: label,
            preferBelow: false,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.92),
              borderRadius: BorderRadius.circular(sc(8)),
              border: Border.all(color: t.accent.withOpacity(0.4)),
            ),
            textStyle: TextStyle(
                color: Colors.white,
                fontSize: sc(11),
                fontWeight: FontWeight.w600),
            child: btn,
          )
        : btn;
  }
}

enum _G { min, max, close }

class _WinBtn extends StatefulWidget {
  final _G kind;
  final AppTheme theme;
  final VoidCallback onPressed;
  final bool isClose;
  const _WinBtn({
    super.key,
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
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(sc(9))),
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
    final w = size.width, h = size.height;
    switch (kind) {
      case _G.min:
        canvas.drawLine(
            Offset(w * 0.15, h * 0.5), Offset(w * 0.85, h * 0.5), p);
        break;
      case _G.max:
        final l = w * 0.15, c = w * 0.30;
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
        canvas.drawLine(
            Offset(w * 0.22, h * 0.22), Offset(w * 0.78, h * 0.78), p);
        canvas.drawLine(
            Offset(w * 0.78, h * 0.22), Offset(w * 0.22, h * 0.78), p);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) =>
      old.color != color || old.kind != kind;
}

class _FinalBuildDialog extends StatelessWidget {
  const _FinalBuildDialog();
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: 380,
            padding: EdgeInsets.all(sc(24)),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0E14).withOpacity(0.92),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 40,
                    offset: const Offset(0, 16)),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: sc(64),
                height: sc(64),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFB3E65C).withOpacity(0.15),
                  border: Border.all(
                      color: const Color(0xFFB3E65C).withOpacity(0.6),
                      width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFB3E65C).withOpacity(0.25),
                        blurRadius: 24),
                  ],
                ),
                child: Icon(Icons.workspace_premium_rounded,
                    size: sc(30), color: const Color(0xFFB3E65C)),
              ),
              SizedBox(height: sc(14)),
              Text('Финальный крупный билд',
                  style: TextStyle(
                      fontSize: sc(16),
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              SizedBox(height: sc(8)),
              Text(
                  'Z2 Mini 1.2.0 — последний большой релиз.\nЕсли дальше и будут обновления — только минорные (фиксы и мелкие правки).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: sc(12),
                      height: 1.5,
                      color: Colors.white.withOpacity(0.7))),
              SizedBox(height: sc(18)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: sc(11)),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Color(0xFFB3E65C),
                      Color(0xFF8FCC4A),
                    ]),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(
                    child: Text('Понятно 🖤',
                        style: TextStyle(
                            fontSize: sc(13),
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0B0E14))),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}