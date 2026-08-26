import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/ui_scale.dart';
import '../core/ui_settings.dart';
import 'liquid_glass_container.dart';
import 'style/widgets.dart';
import 'package:file_picker/file_picker.dart';
import '../core/sound_service.dart';
import '../core/notify_service.dart';
import '../services/zapret_service.dart';
import '../services/update_service.dart';
import 'package:window_manager/window_manager.dart';

class SettingsPage extends StatefulWidget {
  final AppTheme theme;
  const SettingsPage({super.key, required this.theme});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  static int _cat = 0; // 🧯 static: не сбрасывается при пересоздании страницы
  static int _shown = 0;
  double _offsetY = 0;
  double _contentOp = 1;
  Duration _slideDur = Duration.zero;
  Curve _slideCurve = Curves.easeOutCubic;
  int _token = 0;
  late final AnimationController _enter = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 450));
  late final CurvedAnimation _enterCurve =
      CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);

  AppTheme get t => widget.theme;

  static const List<List<Object>> _cats = [
    [Icons.brush_rounded, 'Внешний вид', 'Appearance'],
    [Icons.dashboard_customize_rounded, 'Интерфейс', 'Interface'],
    [Icons.water_drop_rounded, 'Стекло', 'Glass'],
    [Icons.auto_awesome_rounded, 'Свечение', 'Glow'],
    [Icons.graphic_eq_rounded, 'Звук', 'Sound'],
    [Icons.landscape_rounded, 'Фон', 'Background'],
    [Icons.monitor_rounded, 'Графика', 'Graphics'],
    [Icons.info_rounded, 'О программе', 'About'],
  ];

  @override
  void initState() {
    super.initState();
    if (UiSettings.animationsEnabled.value) {
      _enter.forward();
    } else {
      _enter.value = 1;
    }
  }

  @override
  void dispose() {
    _enterCurve.dispose();
    _enter.dispose();
    super.dispose();
  }

  void _goCat(int i) {
    if (i == _cat) return;
    final dir = i > _cat ? 1 : -1;
    setState(() => _cat = i);
    if (!UiSettings.animationsEnabled.value) {
      setState(() => _shown = i);
      return;
    }
    final tk = ++_token;
    setState(() {
      _slideDur = const Duration(milliseconds: 200);
      _slideCurve = Curves.easeInCubic;
      _offsetY = -0.3 * dir;
      _contentOp = 0;
    });
    Future.delayed(const Duration(milliseconds: 210), () {
      if (!mounted || tk != _token) return;
      setState(() {
        _slideDur = Duration.zero;
        _offsetY = 0.3 * dir;
        _contentOp = 0;
        _shown = _cat;
      });
      Future.delayed(const Duration(milliseconds: 30), () {
        if (!mounted || tk != _token) return;
        setState(() {
          _slideDur = const Duration(milliseconds: 260);
          _slideCurve = Curves.easeOutCubic;
          _offsetY = 0;
          _contentOp = 1;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UiSettings.all,
      builder: (ctx, _) {
        return Row(children: [
          SlideTransition(
            position:
                Tween<Offset>(begin: const Offset(-0.25, 0), end: Offset.zero)
                    .animate(_enterCurve),
            child: FadeTransition(opacity: _enterCurve, child: _rail()),
          ),
          VerticalDivider(
              width: 1, color: Colors.white.withOpacity(t.isDark ? 0.08 : 0.3)),
          Expanded(
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0.08, 0), end: Offset.zero)
                  .animate(_enterCurve),
              child: FadeTransition(
                opacity: _enterCurve,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(sc(16), sc(44), sc(64), sc(16)),
                  child: Center(
                    child: ClipRect(
                      child: AnimatedSlide(
                        offset: Offset(0, _offsetY),
                        duration: _slideDur,
                        curve: _slideCurve,
                        child: AnimatedOpacity(
                          opacity: _contentOp,
                          duration: _slideDur,
                          curve: _slideCurve,
                          child: LiquidGlassContainer(
                            theme: t,
                            radius: 24,
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(sc(14)),
                              child: KeyedSubtree(
                                key: ValueKey(_shown),
                                child: _page(_shown),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]);
      },
    );
  }

  Widget _rail() => ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: sc(190),
            color: (t.isDark ? const Color(0xFF0B0E14) : Colors.white)
                .withOpacity(t.isDark ? 0.35 : 0.5),
            child: LayoutBuilder(
              builder: (ctx, c) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _cats.length; i++) ...[
                          if (i > 0) SizedBox(height: sc(6)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: sc(10)),
                            child: _catBtn(i),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _page(int i) {
    switch (i) {
      case 0:
        return _appearance();
      case 1:
        return _interface();
      case 2:
        return _glass();
      case 3:
        return _glow();
      case 4:
        return _sound();
      case 5:
        return _background();
      case 6:
        return _graphics();
      default:
        return _about();
    }
  }

  Widget _catBtn(int i) {
    final active = _cat == i;
    return GestureDetector(
      onTap: () {
        SoundService.click();
        _goCat(i);
      },
      child: AnimatedContainer(
        duration: t.animDur,
        curve: t.animCurve,
        padding: EdgeInsets.symmetric(horizontal: sc(12), vertical: sc(10)),
        decoration: BoxDecoration(
          color: active ? t.accent.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: active ? t.accent.withOpacity(0.5) : Colors.transparent),
        ),
        child: Row(children: [
          Icon(_cats[i][0] as IconData,
              size: sc(16), color: active ? t.accent : t.text.withOpacity(0.5)),
          SizedBox(width: sc(10)),
          Flexible(
            child: Text(tr(_cats[i][1] as String, _cats[i][2] as String),
                style: TextStyle(
                    fontSize: sc(12),
                    fontWeight: FontWeight.w700,
                    color: active ? t.text : t.text.withOpacity(0.6)),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }

  // ── вкладки ────────────────────────────────────────────────
  Widget _appearance() => _col([
        _card(title: tr('Тема', 'Theme'), icon: Icons.palette_rounded, children: [
          _themeSwitch(),
          _sep(),
          _switch(tr('Авто-тема (ночью тёмная)', 'Auto theme'),
              UiSettings.autoTheme.value, () {
            UiSettings.autoTheme.value = !UiSettings.autoTheme.value;
            UiSettings.save();
          }, icon: Icons.schedule_rounded),
        ]),
        _gap(),
        _card(
            title: tr('Цвета', 'Colors'),
            icon: Icons.colorize_rounded,
            children: [
              _colorRow(tr('Цвет акцента', 'Accent color'),
                  UiSettings.accentColor.value ?? t.accent, (c) {
                UiSettings.accentColor.value = c;
                UiSettings.save();
              }, onReset: () {
                UiSettings.accentColor.value = null;
                UiSettings.save();
              }),
              _sep(),
              _switch(tr('Градиентный акцент', 'Gradient accent'),
                  UiSettings.gradientAccent.value, () {
                UiSettings.gradientAccent.value =
                    !UiSettings.gradientAccent.value;
                UiSettings.save();
              }, icon: Icons.gradient_rounded),
              if (UiSettings.gradientAccent.value) ...[
                _sep(),
                _colorRow(tr('Второй цвет', 'Second color'),
                    UiSettings.accent2.value ?? const Color(0xFF22D3EE), (c) {
                  UiSettings.accent2.value = c;
                  UiSettings.save();
                }, onReset: () {
                  UiSettings.accent2.value = null;
                  UiSettings.save();
                }),
              ],
              _sep(),
              _colorRow(tr('Цвет кнопок', 'Button color'),
                  UiSettings.buttonColor.value ?? t.buttonColor, (c) {
                UiSettings.buttonColor.value = c;
                UiSettings.save();
              }, onReset: () {
                UiSettings.buttonColor.value = null;
                UiSettings.save();
              }),
            ]),
      ]);

  Widget _interface() => _col([
        _card(
          title: tr('Интерфейс', 'Interface'),
          icon: Icons.dashboard_customize_rounded,
          children: [
            _slider(tr('Масштаб', 'Scale'), UiSettings.uiScale.value, 0.7, 1.6,
                (v) {
              UiSettings.uiScale.value = v;
              UiScale.value = v;
              UiSettings.save();
            },
                suffix: '${(UiSettings.uiScale.value * 100).toInt()}%',
                factor: 100),
            _sep(),
            _slider(tr('Скругление', 'Radius'), UiSettings.glassRadius.value, 8,
                48, (v) {
              UiSettings.glassRadius.value = v;
              UiSettings.save();
            }),
            _sep(),
            _switch(tr('Сайдбар справа', 'Sidebar right'),
                UiSettings.sidebarRight.value, () {
              UiSettings.sidebarRight.value = !UiSettings.sidebarRight.value;
              UiSettings.save();
            }, icon: Icons.flip_to_front_rounded),
            _sep(),
            Row(children: [
              _chip(tr('Системный шрифт', 'System'),
                  UiSettings.fontMode.value == 0, () {
                UiSettings.fontMode.value = 0;
                UiSettings.save();
              }),
              SizedBox(width: sc(8)),
              _chip(tr('Моно', 'Mono'), UiSettings.fontMode.value == 1, () {
                UiSettings.fontMode.value = 1;
                UiSettings.save();
              }),
            ]),
          ],
        ),
        _gap(),
        _card(
            title: tr('Запуск', 'Startup'),
            icon: Icons.rocket_launch_rounded,
            children: [
              _switch(tr('Бут-анимация', 'Boot animation'),
                  UiSettings.bootEnabled.value, () {
                UiSettings.bootEnabled.value = !UiSettings.bootEnabled.value;
                UiSettings.save();
              }, icon: Icons.play_circle_outline_rounded),
              _sep(),
              _slider(tr('Длительность бут', 'Boot duration'),
                  UiSettings.bootDuration.value, 2.0, 6.0, (v) {
                UiSettings.bootDuration.value = v;
                UiSettings.save();
              },
                  suffix:
                      '${UiSettings.bootDuration.value.toStringAsFixed(1)}s'),
              _sep(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(t.isDark ? 0.35 : 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.accent.withOpacity(0.4)),
                ),
                child: TextField(
                  controller:
                      TextEditingController(text: UiSettings.bootCaption.value),
                  onSubmitted: (s) {
                    UiSettings.bootCaption.value = s;
                    UiSettings.save();
                  },
                  style: TextStyle(color: t.text, fontSize: 12),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    prefixIcon:
                        Icon(Icons.title_rounded, size: 14, color: t.accent),
                    hintText: tr(
                        'Подпись на бут-экране (пусто = стандарт)',
                        'Boot caption (empty = default)'),
                    hintStyle: TextStyle(
                        color: t.text.withOpacity(0.35), fontSize: 11),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: sc(10), vertical: sc(10)),
                  ),
                ),
              ),
            ]),
        _gap(),
        _card(
          title: tr('Поведение', 'Behaviour'),
          icon: Icons.tune_rounded,
          children: [
            _slider(tr('Скорость анимаций', 'Animation speed'),
                UiSettings.animSpeed.value, 0.5, 2.0, (v) {
              UiSettings.animSpeed.value = v;
              UiSettings.save();
            },
                suffix:
                    'x${UiSettings.animSpeed.value.toStringAsFixed(1)}'),
            _sep(),
            _switch(tr('Анимации', 'Animations'),
                UiSettings.animationsEnabled.value, () {
              UiSettings.animationsEnabled.value =
                  !UiSettings.animationsEnabled.value;
              UiSettings.save();
            }, icon: Icons.animation_rounded),
          ],
        ),
      ]);

  Widget _glass() => _col([
        _card(
            title: tr('Размытие', 'Blur'),
            icon: Icons.water_drop_rounded,
            children: [
              _switch(tr('Реальный blur (GPU)', 'Real blur (GPU)'),
                  UiSettings.realBlur.value, () {
                UiSettings.realBlur.value = !UiSettings.realBlur.value;
                UiSettings.save();
              }, icon: Icons.blur_on_rounded),
              _sep(),
              _slider(
                  tr('Размытие', 'Blur'), UiSettings.blurSigma.value, 0, 50,
                  (v) {
                UiSettings.blurSigma.value = v;
                UiSettings.save();
              }),
              _sep(),
              _slider(tr('Насыщенность', 'Saturation'),
                  UiSettings.saturation.value, 1.0, 2.0, (v) {
                UiSettings.saturation.value = v;
                UiSettings.save();
              }, suffix: UiSettings.saturation.value.toStringAsFixed(2)),
              _sep(),
              _slider(tr('Прозрачность', 'Opacity'),
                  UiSettings.glassOpacity.value, 0.0, 0.8, (v) {
                UiSettings.glassOpacity.value = v;
                UiSettings.save();
              }, suffix: UiSettings.glassOpacity.value.toStringAsFixed(2)),
            ]),
        _gap(),
        _card(
            title: tr('Оттенок', 'Tint'),
            icon: Icons.colorize_rounded,
            children: [
              _colorRow(tr('Оттенок стекла', 'Glass tint'),
                  UiSettings.glassTint.value, (c) {
                UiSettings.glassTint.value = c;
                UiSettings.save();
              }),
              _sep(),
              Btn25D(
                base: t.accent,
                radius: 999,
                onTap: () => UiSettings.resetGlass(),
                padding: EdgeInsets.symmetric(vertical: sc(9)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restart_alt_rounded,
                        size: sc(14), color: t.buttonTextColor),
                    SizedBox(width: sc(8)),
                    Text(tr('Сброс', 'Reset'),
                        style: TextStyle(
                            fontSize: sc(12),
                            color: t.buttonTextColor,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ]),
      ]);

  Widget _glow() => _col([
        _card(
          title: tr('Свечение и грани', 'Glow & Edges'),
          icon: Icons.auto_awesome_rounded,
          children: [
            _slider(tr('Блик по краям', 'Edge glow'),
                UiSettings.edgeGlow.value, 0, 1, (v) {
              UiSettings.edgeGlow.value = v;
              UiSettings.save();
            }, suffix: UiSettings.edgeGlow.value.toStringAsFixed(2)),
            _sep(),
            _slider(tr('Граница', 'Border'),
                UiSettings.borderOpacity.value, 0, 0.6, (v) {
              UiSettings.borderOpacity.value = v;
              UiSettings.save();
            }, suffix: UiSettings.borderOpacity.value.toStringAsFixed(2)),
            _sep(),
            _slider(tr('Верхний блик', 'Specular'), UiSettings.specular.value,
                0, 1, (v) {
              UiSettings.specular.value = v;
              UiSettings.save();
            }, suffix: UiSettings.specular.value.toStringAsFixed(2)),
          ],
        ),
      ]);

  Widget _background() => _col([
        _card(
            title: tr('Стиль', 'Style'),
            icon: Icons.landscape_rounded,
            children: [
              _switch(tr('Живой фон', 'Live background'),
                  UiSettings.liveBg.value, () {
                UiSettings.liveBg.value = !UiSettings.liveBg.value;
                UiSettings.save();
              }),
              _sep(),
              ValueListenableBuilder<int>(
                valueListenable: UiSettings.bgStyle,
                builder: (ctx, st, _) => Row(children: [
                  _bgChip(0, Icons.cloud_rounded,
                      tr('Аврора', 'Aurora'), st),
                  SizedBox(width: sc(6)),
                  _bgChip(1, Icons.waves_rounded, tr('Волны', 'Waves'), st),
                  SizedBox(width: sc(6)),
                  _bgChip(2, Icons.nightlight_rounded,
                      tr('Звёзды', 'Stars'), st),
                  SizedBox(width: sc(6)),
                  _bgChip(3, Icons.flashlight_on_rounded,
                      tr('Моя волна', 'My Wave'), st),
                  SizedBox(width: sc(6)),
                  _bgChip(4, Icons.filter_drama_rounded,
                      tr('Облака', 'Clouds'), st),
                ]),
              ),
            ]),
        _gap(),
        _card(
            title: tr('Настройка', 'Tuning'),
            icon: Icons.speed_rounded,
            children: [
              _slider(tr('Скорость фона', 'Background speed'),
                  UiSettings.auroraSpeed.value, 0.3, 3.0, (v) {
                UiSettings.auroraSpeed.value = v;
                UiSettings.save();
              },
                  suffix:
                      'x${UiSettings.auroraSpeed.value.toStringAsFixed(1)}'),
              _sep(),
              _slider(
                  tr('Виньетка', 'Vignette'), UiSettings.vignette.value, 0.0, 0.8,
                  (v) {
                UiSettings.vignette.value = v;
                UiSettings.save();
              }, suffix: UiSettings.vignette.value.toStringAsFixed(2)),
              _sep(),
              _switch(tr('Параллакс', 'Parallax'), UiSettings.parallax.value,
                  () {
                UiSettings.parallax.value = !UiSettings.parallax.value;
                UiSettings.save();
              }, icon: Icons.motion_photos_on_rounded),
              _sep(),
              _colorRow(tr('Цвет фона', 'Background color'),
                  UiSettings.bgColor.value ?? t.accent, (c) {
                UiSettings.bgColor.value = c;
                UiSettings.save();
              }, onReset: () {
                UiSettings.bgColor.value = null;
                UiSettings.save();
              }),
            ]),
      ]);

  Widget _graphics() => _col([
        _card(
            title: tr('Кадровая частота', 'Frame rate'),
            icon: Icons.monitor_rounded,
            children: [
              Row(children: [
                for (final f in [12, 24, 30, 60]) ...[
                  Expanded(child: _fpsChip(f)),
                  if (f != 60) SizedBox(width: sc(6)),
                ],
              ]),
              _sep(),
              _switch(
                  tr('Экономия энергии', 'Power saving'),
                  UiSettings.ecoMode.value, () {
                final on = !UiSettings.ecoMode.value;
                UiSettings.ecoMode.value = on;
                if (on) UiSettings.parallax.value = false;
                UiSettings.save();
              }, icon: Icons.battery_saver_rounded),
              _sep(),
              _switch(
                  tr('Тени карточек и кнопок', 'Card & button shadows'),
                  UiSettings.cardShadows.value, () {
                UiSettings.cardShadows.value = !UiSettings.cardShadows.value;
                UiSettings.save();
              }, icon: Icons.layers_rounded),
            ]),
      ]);

  Widget _fpsChip(int f) {
    final active = UiSettings.fpsCap.value == f;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SoundService.toggle();
        UiSettings.fpsCap.value = f;
        UiSettings.save();
      },
      child: AnimatedContainer(
        duration: t.animDur,
        curve: t.animCurve,
        padding: EdgeInsets.symmetric(vertical: sc(9)),
        decoration: BoxDecoration(
          color: active ? t.accent.withOpacity(0.8) : t.card.withOpacity(0.5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: active
                  ? t.accent
                  : Colors.white.withOpacity(t.isDark ? 0.10 : 0.5)),
        ),
        child: Center(
          child: Text('$f FPS',
              style: TextStyle(
                  fontSize: sc(11),
                  fontWeight: FontWeight.w800,
                  color:
                      active ? t.buttonTextColor : t.text.withOpacity(0.6))),
        ),
      ),
    );
  }

  Widget _sound() => _col([
        _card(
            title: tr('Звук', 'Sound'),
            icon: Icons.graphic_eq_rounded,
            children: [
              _switch(tr('Звуки интерфейса', 'Interface sounds'),
                  UiSettings.soundEnabled.value, () {
                UiSettings.soundEnabled.value = !UiSettings.soundEnabled.value;
                UiSettings.save();
                if (UiSettings.soundEnabled.value) SoundService.toggle();
              }, icon: Icons.graphic_eq_rounded),
              _sep(),
              ValueListenableBuilder<double>(
                valueListenable: UiSettings.soundVolume,
                builder: (ctx, v, _) =>
                    _slider(tr('Громкость', 'Volume'), v, 0.0, 1.0, (x) {
                  UiSettings.soundVolume.value = x;
                  UiSettings.save();
                }, suffix: '${(v * 100).toInt()}%', factor: 100),
              ),
              _sep(),
              Btn25D(
                base: t.surface,
                radius: 999,
                onTap: () {
                  final dir =
                      '${File(Platform.resolvedExecutable).parent.path}\\data\\flutter_assets\\assets';
                  Process.run('explorer', [dir]);
                },
                padding:
                    EdgeInsets.symmetric(horizontal: sc(12), vertical: sc(9)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open_rounded,
                        size: sc(14), color: t.accent),
                    SizedBox(width: sc(6)),
                    Text(tr('Папка со звуками', 'Sounds folder'),
                        style: TextStyle(
                            fontSize: sc(11),
                            color: t.text,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ]),
        _gap(),
        _card(
            title: tr('События', 'Events'),
            icon: Icons.tune_rounded,
            children: [
              for (final e in [
                'start',
                'stop',
                'restart',
                'click',
                'toggle',
                'on',
                'off',
                'notify',
                'update',
                'complete',
                'error',
              ])
                _soundRow(e),
            ]),
      ]);

  Widget _soundRow(String event) {
    final custom = UiSettings.soundPath(event);
    final name = custom == null
        ? tr('Стандартный', 'Default')
        : custom.replaceAll('\\', '/').split('/').last;
    return Padding(
      padding: EdgeInsets.only(top: sc(6)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: sc(10), vertical: sc(6)),
        decoration: BoxDecoration(
          color: t.card.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withOpacity(t.isDark ? 0.10 : 0.5)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(SoundService.labels[event] ?? event,
                      style: TextStyle(
                          fontSize: sc(12),
                          fontWeight: FontWeight.w700,
                          color: t.text)),
                  Text(name,
                      style: TextStyle(
                          fontSize: sc(10), color: t.text.withOpacity(0.5)),
                      overflow: TextOverflow.ellipsis),
                ]),
          ),
          _iconBtn(Icons.play_arrow_rounded,
              () => SoundService.preview(event),
              click: false),
          SizedBox(width: sc(6)),
          _iconBtn(Icons.folder_open_rounded, () async {
            final picked =
                await FilePicker.platform.pickFiles(type: FileType.audio);
            if (picked != null && picked.files.isNotEmpty) {
              final path = picked.files.first.path;
              if (path != null) {
                UiSettings.setSoundPath(event, path);
                setState(() {});
                SoundService.preview(event);
              }
            }
          }),
          SizedBox(width: sc(6)),
          _iconBtn(Icons.close_rounded, () {
            UiSettings.setSoundPath(event, null);
            setState(() {});
          }),
        ]),
      ),
    );
  }

  Widget _about() => _col([
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: sc(26), horizontal: sc(16)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                t.accent.withOpacity(0.18),
                t.accent.withOpacity(0.05),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(sc(22)),
            border: Border.all(color: t.accent.withOpacity(0.3)),
          ),
          child: Column(children: [
            Container(
              width: sc(68),
              height: sc(68),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    Border.all(color: t.accent.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: t.accent.withOpacity(0.4), blurRadius: sc(26)),
                ],
              ),
              child: ClipOval(
                  child: Image.asset('assets/z2m_black_logo_256.png')),
            ),
            SizedBox(height: sc(14)),
            Text('Z2 Mini',
                style: TextStyle(
                    fontSize: sc(22),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: t.text)),
            SizedBox(height: sc(8)),
            Container(
              padding: EdgeInsets.symmetric(horizontal: sc(12), vertical: sc(5)),
              decoration: BoxDecoration(
                color: t.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: t.accent.withOpacity(0.4)),
              ),
              child: Text('v${UpdateService.currentVersion} · Liquid Glass Edition',
                  style: TextStyle(
                      fontSize: sc(10),
                      fontWeight: FontWeight.w700,
                      color: t.accent)),
            ),
            SizedBox(height: sc(12)),
            Text(
              tr(
                  'Мини-менеджер Zapret: обход блокировок YouTube, Discord и игр. Основан на Z2 Manager.',
                  'Mini manager for Zapret: bypass blocks of YouTube, Discord and games. Based on Z2 Manager.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: sc(11),
                  height: 1.55,
                  color: t.text.withOpacity(0.55)),
            ),
          ]),
        ),
        _gap(),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: _card(
              title: tr('Язык и окно', 'Language & Window'),
              icon: Icons.translate_rounded,
              children: [
                Row(children: [
                  _chip('RU', UiSettings.language.value == 'RU',
                      () => UiSettings.setLang('RU')),
                  SizedBox(width: sc(8)),
                  _chip('EN', UiSettings.language.value == 'EN',
                      () => UiSettings.setLang('EN')),
                ]),
                _sep(),
                _switch(tr('Крестик — в трей', 'Close to tray'),
                    UiSettings.closeToTray.value, () {
                  UiSettings.closeToTray.value = !UiSettings.closeToTray.value;
                  UiSettings.save();
                }, icon: Icons.system_security_update_rounded),
                _sep(),
                _switch(tr('Окно поверх всех', 'Always on top'),
                    UiSettings.alwaysOnTop.value, () {
                  UiSettings.alwaysOnTop.value = !UiSettings.alwaysOnTop.value;
                  UiSettings.save();
                  windowManager.setAlwaysOnTop(UiSettings.alwaysOnTop.value);
                }, icon: Icons.push_pin_rounded),
                _sep(),
                _slider(tr('Прозрачность окна', 'Window opacity'),
                    UiSettings.windowOpacity.value, 0.5, 1.0, (v) {
                  UiSettings.windowOpacity.value = v;
                  UiSettings.save();
                  windowManager.setOpacity(v);
                },
                    suffix:
                        '${(UiSettings.windowOpacity.value * 100).toInt()}%',
                    factor: 100),
              ],
            ),
          ),
          SizedBox(width: sc(10)),
          Expanded(
            child: _card(
              title: tr('Данные', 'Data'),
              icon: Icons.folder_rounded,
              children: [
                Btn25D(
                  base: t.surface,
                  radius: 999,
                  onTap: _pickZapretFolder,
                  padding: EdgeInsets.symmetric(
                      horizontal: sc(12), vertical: sc(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_zip_rounded,
                          size: sc(14), color: t.accent),
                      SizedBox(width: sc(6)),
                      Flexible(
                        child: Text(
                          UiSettings.zapretPath.value ?? r'C:\zapret_programm',
                          style: TextStyle(
                              fontSize: sc(11),
                              color: t.text,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                _sep(),
                Btn25D(
                  base: t.surface,
                  radius: 999,
                  onTap: () async {
                    final url =
                        Uri.parse('https://github.com/Ank01rd/ZapretManager');
                    if (await canLaunchUrl(url)) await launchUrl(url);
                  },
                  padding: EdgeInsets.symmetric(
                      horizontal: sc(12), vertical: sc(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.code_rounded, size: sc(14), color: t.accent),
                      SizedBox(width: sc(6)),
                      Text('GitHub',
                          style: TextStyle(
                              fontSize: sc(11),
                              color: t.text,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                _sep(),
                Btn25D(
                  base: t.surface,
                  radius: 999,
                  onTap: () {
                    final dir = '${Platform.environment['APPDATA']}\\Z2Mini';
                    Directory(dir).createSync(recursive: true);
                    Process.run('explorer', [dir]);
                  },
                  padding: EdgeInsets.symmetric(
                      horizontal: sc(12), vertical: sc(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open_rounded,
                          size: sc(14), color: t.accent),
                      SizedBox(width: sc(6)),
                      Text(tr('Папка данных', 'Data folder'),
                          style: TextStyle(
                              fontSize: sc(11),
                              color: t.text,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                _sep(),
                Btn25D(
                  base: t.surface,
                  radius: 999,
                  onTap: () {
                    UiSettings.resetAll();
                    NotifyService.push(
                        tr('Настройки сброшены', 'Settings reset'),
                        icon: Icons.restart_alt_rounded);
                  },
                  padding: EdgeInsets.symmetric(
                      horizontal: sc(12), vertical: sc(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restart_alt_rounded,
                          size: sc(14), color: const Color(0xFFEF4444)),
                      SizedBox(width: sc(6)),
                      Text(tr('Сбросить все настройки', 'Reset all settings'),
                          style: TextStyle(
                              fontSize: sc(11),
                              color: const Color(0xFFEF4444),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]),
      ]);

  Future<void> _pickZapretFolder() async {
    final dir = await FilePicker.platform.getDirectoryPath();
    if (dir == null) return;
    final looksLikeZapret = await File('$dir\\service.bat').exists() ||
        await File('$dir\\general.bat').exists() ||
        await File('$dir\\bin\\winws.exe').exists() ||
        await File('$dir\\winws.exe').exists();
    if (!looksLikeZapret) {
      NotifyService.push(
        tr('Это не папка Zapret: нет service.bat или winws.exe',
            'Not a Zapret folder: no service.bat or winws.exe'),
        icon: Icons.warning_amber_rounded,
        soundEvent: 'error',
      );
      return;
    }
    await ZapretService.instance.savePath(dir);
    ZapretService.instance.zapretDir = dir;
    UiSettings.zapretPath.value = dir;
    UiSettings.save();
    NotifyService.push(tr('Папка Zapret сохранена', 'Zapret folder saved'),
        icon: Icons.folder_rounded);
  }

  Widget _iconBtn(IconData ic, VoidCallback onTap, {bool click = true}) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (click) SoundService.click();
          onTap();
        },
        child: Container(
          width: sc(30),
          height: sc(30),
          decoration: BoxDecoration(
            color: t.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(ic, size: sc(15), color: t.accent),
        ),
      );

  // ── хелперы ────────────────────────────────────────────────
  Widget _col(List<Widget> c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: c,
      );

  Widget _card(
          {String? title, IconData? icon, required List<Widget> children}) =>
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(sc(14)),
        decoration: BoxDecoration(
          color: t.card.withOpacity(0.45),
          borderRadius: BorderRadius.circular(sc(18)),
          border: Border.all(
              color: Colors.white.withOpacity(t.isDark ? 0.08 : 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(children: [
                Icon(icon, size: sc(14), color: t.accent),
                SizedBox(width: sc(6)),
                Text(title.toUpperCase(),
                    style: TextStyle(
                        fontSize: sc(10),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: t.text.withOpacity(0.5))),
              ]),
              SizedBox(height: sc(10)),
            ],
            ...children,
          ],
        ),
      );

  Widget _gap() => SizedBox(height: sc(10));

  Widget _sep() => Padding(
        padding: EdgeInsets.symmetric(vertical: sc(7)),
        child: Container(
          height: 1,
          color: Colors.white.withOpacity(t.isDark ? 0.08 : 0.25),
        ),
      );

  Widget _switch(String label, bool value, VoidCallback onChanged,
          {IconData icon = Icons.waves_rounded}) =>
      Container(
        margin: EdgeInsets.only(top: sc(2)),
        padding: EdgeInsets.symmetric(horizontal: sc(14), vertical: sc(4)),
        decoration: BoxDecoration(
          color: t.card.withOpacity(0.5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: Colors.white.withOpacity(t.isDark ? 0.10 : 0.5)),
        ),
        child: Row(children: [
          Icon(icon, color: t.accent, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.text)),
          ),
          Switch(
            value: value,
            onChanged: (_) {
              if (value) {
                SoundService.off();
              } else {
                SoundService.on();
              }
              onChanged();
            },
            activeColor: t.buttonTextColor,
            activeTrackColor: t.buttonColor.withOpacity(0.5),
            inactiveThumbColor: t.text.withOpacity(0.45),
            inactiveTrackColor: t.card.withOpacity(0.9),
          ),
        ]),
      );

  Widget _slider(String label, double value, double min, double max,
          ValueChanged<double> on,
          {String? suffix, double factor = 1}) =>
      Padding(
        padding: EdgeInsets.only(top: sc(4)),
        child: Row(children: [
          SizedBox(
            width: sc(120),
            child:
                Text(label, style: TextStyle(fontSize: 12, color: t.text)),
          ),
          Expanded(
            child: _GlassSlider(
              value: value,
              min: min,
              max: max,
              onChanged: on,
              accent: t.accent,
              accent2: UiSettings.gradientAccent.value
                  ? (UiSettings.accent2.value ?? t.accent)
                  : null,
            ),
          ),
          _ValuePill(
            text: suffix ?? value.toStringAsFixed(0),
            factor: factor,
            min: min,
            max: max,
            on: on,
            accent: t.accent,
            bg: Colors.black.withOpacity(t.isDark ? 0.35 : 0.06),
            textColor: t.text,
          ),
        ]),
      );

  Widget _chip(String label, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: () {
          SoundService.toggle();
          onTap();
        },
        child: AnimatedContainer(
          duration: t.animDur,
          curve: t.animCurve,
          padding: EdgeInsets.symmetric(horizontal: sc(16), vertical: sc(9)),
          decoration: BoxDecoration(
            color: active ? t.accent.withOpacity(0.8) : t.card.withOpacity(0.5),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active
                  ? t.accent
                  : Colors.white.withOpacity(t.isDark ? 0.10 : 0.5),
            ),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? t.buttonTextColor : t.text,
              )),
        ),
      );

  Widget _colorRow(String label, Color current, ValueChanged<Color> on,
          {VoidCallback? onReset}) =>
      Padding(
        padding: EdgeInsets.only(top: sc(2)),
        child: Btn25D(
          base: t.surface,
          radius: 999,
          onTap: () => _pick(label, current, on, onReset: onReset),
          padding: EdgeInsets.symmetric(horizontal: sc(14), vertical: sc(9)),
          child: Row(children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: current,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: t.text,
                      fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.colorize_rounded,
                size: 15, color: t.text.withOpacity(0.6)),
          ]),
        ),
      );

  void _pick(String title, Color initial, ValueChanged<Color> apply,
      {VoidCallback? onReset}) {
    showDialog(
      context: context,
      builder: (c) => _ColorPickerDialog(
        theme: t,
        title: title,
        initial: initial,
        onApply: apply,
        onReset: onReset,
      ),
    );
  }

  Widget _themeSwitch() => ValueListenableBuilder<bool>(
        valueListenable: UiSettings.isDark,
        builder: (ctx, isDark, _) => Container(
          height: sc(46),
          decoration: BoxDecoration(
            color: t.card.withOpacity(0.5),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: Colors.white.withOpacity(t.isDark ? 0.10 : 0.5)),
          ),
          child: LayoutBuilder(builder: (ctx, c) {
            final w = c.maxWidth;
            return Stack(alignment: Alignment.center, children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                left: isDark ? sc(4) : w / 2 + sc(2),
                width: w / 2 - sc(6),
                top: sc(4),
                bottom: sc(4),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      t.accent.withOpacity(0.9),
                      t.accent.withOpacity(0.6),
                    ]),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: t.accent.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(children: [
                  Expanded(
                    child: _themeOpt(Icons.dark_mode_rounded,
                        tr('Тёмная', 'Dark'), isDark, true),
                  ),
                  Expanded(
                    child: _themeOpt(Icons.light_mode_rounded,
                        tr('Светлая', 'Light'), !isDark, false),
                  ),
                ]),
              ),
            ]);
          }),
        ),
      );

  Widget _themeOpt(IconData ic, String label, bool active, bool value) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          SoundService.toggle();
          UiSettings.isDark.value = value;
          UiSettings.save();
        },
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(ic,
              size: sc(15),
              color: active ? t.buttonTextColor : t.text.withOpacity(0.6)),
          SizedBox(width: sc(6)),
          Text(label,
              style: TextStyle(
                  fontSize: sc(12),
                  fontWeight: FontWeight.w700,
                  color: active
                      ? t.buttonTextColor
                      : t.text.withOpacity(0.6))),
        ]),
      );

  Widget _bgChip(int id, IconData ic, String label, int current) {
    final active = current == id;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          SoundService.toggle();
          UiSettings.bgStyle.value = id;
          UiSettings.save();
        },
        child: AnimatedContainer(
          duration: t.animDur,
          curve: t.animCurve,
          padding: EdgeInsets.symmetric(horizontal: sc(8), vertical: sc(9)),
          decoration: BoxDecoration(
            color: active ? t.accent.withOpacity(0.8) : t.card.withOpacity(0.5),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active
                  ? t.accent
                  : Colors.white.withOpacity(t.isDark ? 0.10 : 0.5),
            ),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(ic,
                size: sc(13),
                color: active ? t.buttonTextColor : t.text.withOpacity(0.6)),
            SizedBox(width: sc(4)),
            Flexible(
              child: Text(label,
                  style: TextStyle(
                      fontSize: sc(10),
                      fontWeight: FontWeight.w700,
                      color: active
                          ? t.buttonTextColor
                          : t.text.withOpacity(0.6)),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      ),
    );
  }
}  // ← закрытие _SettingsPageState

// 💊 компактная таблетка значения: тап → ввод числа, клампит в min/max
class _ValuePill extends StatefulWidget {
  final String text;
  final double factor, min, max;
  final ValueChanged<double> on;
  final Color accent;
  final Color bg;
  final Color textColor;
  const _ValuePill({
    required this.text,
    required this.factor,
    required this.min,
    required this.max,
    required this.on,
    required this.accent,
    required this.bg,
    required this.textColor,
  });
  @override
  State<_ValuePill> createState() => _ValuePillState();
}

class _ValuePillState extends State<_ValuePill> {
  bool _edit = false;
  final _c = TextEditingController();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _commit() {
    final p = double.tryParse(_c.text.trim().replaceAll(',', '.'));
    setState(() => _edit = false);
    if (p == null) return;
    widget.on((p / widget.factor).clamp(widget.min, widget.max));
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: sc(42),
        height: sc(18),
        child: _edit
            ? Container(
                decoration: BoxDecoration(
                  color: widget.bg,
                  borderRadius: BorderRadius.circular(sc(6)),
                  border: Border.all(color: widget.accent.withOpacity(0.6)),
                ),
                child: TextField(
                  controller: _c,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 9,
                      color: widget.textColor,
                      fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _commit(),
                  onTapOutside: (_) => _commit(),
                ),
              )
            : GestureDetector(
                onTap: () {
                  _c.text = widget.text.replaceAll(RegExp(r'[^0-9.,]'), '');
                  setState(() => _edit = true);
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.bg,
                    borderRadius: BorderRadius.circular(sc(6)),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: Text(widget.text,
                      style: TextStyle(
                          fontSize: 9,
                          color: widget.textColor,
                          fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                ),
              ),
      );
}

// ============================================================
// 🎨 Колорпикер
// ============================================================
class _ColorPickerDialog extends StatefulWidget {
  final AppTheme theme;
  final String title;
  final Color initial;
  final ValueChanged<Color> onApply;
  final VoidCallback? onReset;
  const _ColorPickerDialog({
    required this.theme,
    required this.title,
    required this.initial,
    required this.onApply,
    this.onReset,
  });
  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late double _h, _s, _v, _a;
  late TextEditingController _hexC;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initial);
    _h = hsv.hue;
    _s = hsv.saturation;
    _v = hsv.value;
    _a = widget.initial.opacity;
    _hexC = TextEditingController(text: _hexText());
  }

  @override
  void dispose() {
    _hexC.dispose();
    super.dispose();
  }

  Color get _solid => HSVColor.fromAHSV(1, _h, _s, _v).toColor();
  Color get _full => _solid.withOpacity(_a);
  String _hexText() =>
      '#${(_solid.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  void _emit() {
    widget.onApply(_full);
    _hexC.text = _hexText();
  }

  void _onHex(String s) {
    final clean = s.trim().replaceAll('#', '');
    if (clean.length != 6 && clean.length != 8) return;
    final v = int.tryParse(clean, radix: 16);
    if (v == null) return;
    final c = Color(clean.length == 8 ? v : (0xFF000000 | v));
    final hsv = HSVColor.fromColor(c);
    setState(() {
      _h = hsv.hue;
      _s = hsv.saturation;
      _v = hsv.value;
      if (clean.length == 8) _a = c.opacity;
    });
    widget.onApply(_full);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: 340,
            padding: EdgeInsets.all(sc(20)),
            decoration: BoxDecoration(
              color: (t.isDark ? const Color(0xFF0B0E14) : Colors.white)
                  .withOpacity(t.isDark ? 0.78 : 0.88),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: Colors.white.withOpacity(t.isDark ? 0.15 : 0.6),
                  width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                    color: t.accent.withOpacity(0.10), blurRadius: 30),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: sc(30),
                    height: sc(30),
                    decoration: BoxDecoration(
                      color: t.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(9),
                      border:
                          Border.all(color: t.accent.withOpacity(0.4)),
                    ),
                    child: Icon(Icons.colorize_rounded,
                        size: sc(15), color: t.accent),
                  ),
                  SizedBox(width: sc(10)),
                  Expanded(
                    child: Text(widget.title,
                        style: TextStyle(
                            color: t.text,
                            fontSize: sc(15),
                            fontWeight: FontWeight.w800)),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: sc(26),
                    height: sc(26),
                    decoration: BoxDecoration(
                      color: _full,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                            color: _full.withOpacity(0.5),
                            blurRadius: 10)
                      ],
                    ),
                  ),
                ]),
                SizedBox(height: sc(14)),
                _svField(),
                SizedBox(height: sc(12)),
                _hueBar(),
                SizedBox(height: sc(10)),
                _alphaBar(),
                SizedBox(height: sc(14)),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(t.isDark ? 0.35 : 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.accent.withOpacity(0.4)),
                  ),
                  child: TextField(
                    controller: _hexC,
                    onSubmitted: _onHex,
                    style: TextStyle(
                        color: t.text,
                        fontSize: 12,
                        fontFamily: 'Consolas'),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.tag_rounded,
                          size: 14, color: t.accent),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: sc(10), vertical: sc(10)),
                    ),
                  ),
                ),
                SizedBox(height: sc(16)),
                Row(children: [
                  if (widget.onReset != null) ...[
                    Expanded(
                      child: Btn25D(
                        base: t.surface,
                        radius: 999,
                        onTap: () {
                          widget.onReset!();
                          Navigator.pop(context);
                        },
                        padding: EdgeInsets.symmetric(vertical: sc(10)),
                        child: Center(
                          child: Text(tr('Сбросить', 'Reset'),
                              style: TextStyle(
                                  color: t.text.withOpacity(0.7),
                                  fontSize: sc(12),
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    SizedBox(width: sc(10)),
                  ],
                  Expanded(
                    child: Btn25D(
                      base: t.accent,
                      radius: 999,
                      onTap: () => Navigator.pop(context),
                      padding: EdgeInsets.symmetric(vertical: sc(10)),
                      child: Center(
                        child: Text(tr('Готово', 'Done'),
                            style: TextStyle(
                                color: t.buttonTextColor,
                                fontSize: sc(12),
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _svField() => LayoutBuilder(builder: (ctx, c) {
        final w = c.maxWidth, hgt = sc(150);
        void handle(Offset p) {
          setState(() {
            _s = (p.dx / w).clamp(0.0, 1.0);
            _v = 1 - (p.dy / hgt).clamp(0.0, 1.0);
          });
          _emit();
        }
        final hueColor = HSVColor.fromAHSV(1, _h, 1, 1).toColor();
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) => handle(d.localPosition),
          onPanUpdate: (d) => handle(d.localPosition),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: hgt,
              child: Stack(children: [
                Positioned.fill(child: Container(color: hueColor)),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.white,
                        Colors.white.withOpacity(0),
                      ]),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: _s * w - sc(9),
                  top: (1 - _v) * hgt - sc(9),
                  child: IgnorePointer(
                    child: Container(
                      width: sc(18),
                      height: sc(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _solid,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 8)
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        );
      });

  Widget _hueBar() => LayoutBuilder(builder: (ctx, c) {
        final w = c.maxWidth;
        void handle(Offset p) {
          setState(() => _h = ((p.dx / w).clamp(0.0, 1.0)) * 360);
          _emit();
        }
        return SizedBox(
          height: sc(14),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (d) => handle(d.localPosition),
            onPanUpdate: (d) => handle(d.localPosition),
            child: Stack(children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Color(0xFFFF0000),
                      Color(0xFFFFFF00),
                      Color(0xFF00FF00),
                      Color(0xFF00FFFF),
                      Color(0xFF0000FF),
                      Color(0xFFFF00FF),
                      Color(0xFFFF0000),
                    ]),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                ),
              ),
              Positioned(
                left: (_h / 360) * (w - sc(16)),
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      width: sc(16),
                      height: sc(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: HSVColor.fromAHSV(1, _h, 1, 1).toColor(),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 6)
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        );
      });

  Widget _alphaBar() => LayoutBuilder(builder: (ctx, c) {
        final w = c.maxWidth;
        void handle(Offset p) {
          setState(() => _a = (p.dx / w).clamp(0.0, 1.0));
          _emit();
        }
        return SizedBox(
          height: sc(14),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (d) => handle(d.localPosition),
            onPanUpdate: (d) => handle(d.localPosition),
            child: Stack(children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: CustomPaint(painter: _CheckerPainter()),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_solid.withOpacity(0), _solid],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                ),
              ),
              Positioned(
                left: _a * (w - sc(16)),
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      width: sc(16),
                      height: sc(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _full,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 6)
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        );
      });
}

class _GlassSlider extends StatefulWidget {
  final double value, min, max;
  final ValueChanged<double> onChanged;
  final Color accent;
  final Color? accent2;
  const _GlassSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.accent,
    this.accent2,
  });
  @override
  State<_GlassSlider> createState() => _GlassSliderState();
}

class _GlassSliderState extends State<_GlassSlider> {
  bool _drag = false;
  double get _p =>
      ((widget.value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

  void _set(double width, double dx) {
    final p = (dx / width).clamp(0.0, 1.0);
    widget.onChanged(widget.min + p * (widget.max - widget.min));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _set(c.maxWidth, d.localPosition.dx),
        onPanDown: (d) {
          setState(() => _drag = true);
          _set(c.maxWidth, d.localPosition.dx);
        },
        onPanUpdate: (d) => _set(c.maxWidth, d.localPosition.dx),
        onPanEnd: (_) => setState(() => _drag = false),
        onPanCancel: () => setState(() => _drag = false),
        child: SizedBox(
          height: sc(24),
          child: Stack(children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  height: sc(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: _p,
                  child: Container(
                    height: sc(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.accent2 != null
                            ? [widget.accent, widget.accent2!]
                            : [
                                widget.accent.withOpacity(0.7),
                                widget.accent
                              ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accent.withOpacity(0.45),
                          blurRadius: _drag ? sc(12) : sc(6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: _p * (c.maxWidth - sc(18)),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  width: _drag ? sc(20) : sc(16),
                  height: _drag ? sc(20) : sc(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                        color: widget.accent.withOpacity(0.9), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accent.withOpacity(0.55),
                        blurRadius: _drag ? sc(16) : sc(8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }
}

class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const s = 6.0;
    final light = Paint()..color = const Color(0xFF3A3A3A);
    final dark = Paint()..color = const Color(0xFF242424);
    for (var y = 0; y < size.height / s + 1; y++) {
      for (var x = 0; x < size.width / s + 1; x++) {
        canvas.drawRect(Rect.fromLTWH(x * s, y * s, s, s),
            (x + y) % 2 == 0 ? light : dark);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}