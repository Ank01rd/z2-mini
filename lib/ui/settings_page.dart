import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
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
import '../core/preset_service.dart';
import 'package:flutter/services.dart';
import '../core/fx_service.dart';

class SettingsPage extends StatefulWidget {
  final AppTheme theme;
  final ValueNotifier<int>? externalCat;
  const SettingsPage({super.key, required this.theme, this.externalCat});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  int get _cat => widget.externalCat?.value ?? _localCat;
  int _localCat = 0;
  static int _shown = 0;
  int _logoTaps = 0;
  Timer? _logoTimer;
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
    [Icons.bookmark_rounded, 'Пресеты', 'Presets'],
    [Icons.info_rounded, 'О программе', 'About'],
  ];

  @override
  void initState() {
    super.initState();
    widget.externalCat?.addListener(_onExternalCat);
    if (UiSettings.animationsEnabled.value) {
      _enter.forward();
    } else {
      _enter.value = 1;
    }
  }

  void _onExternalCat() {
    final i = widget.externalCat!.value;
    if (i == _shown) return;
    _animateTo(i);
  }

  @override
  void dispose() {
    widget.externalCat?.removeListener(_onExternalCat);
    _enterCurve.dispose();
    _enter.dispose();
    super.dispose();
  }

  void _goCat(int i) {
    if (i == _cat) return;
    if (widget.externalCat != null) {
      widget.externalCat!.value = i;
    } else {
      _localCat = i;
      _animateTo(i);
    }
  }

  void _animateTo(int i) {
    final dir = i > _shown ? 1 : -1;
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
        _shown = i;
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
      animation: Listenable.merge([
        UiSettings.all,
        if (widget.externalCat != null) widget.externalCat!,
      ]),
      builder: (ctx, _) {
        return ValueListenableBuilder<int>(
          valueListenable: UiSettings.sidebarPos,
          builder: (ctx, pos, _) {
            final hz = pos == 2 || pos == 3;
            if (hz) {
              return _contentPane();
            }
            final rail = SlideTransition(
              position: Tween<Offset>(
                      begin:
                          hz ? const Offset(0, -0.25) : const Offset(-0.25, 0),
                      end: Offset.zero)
                  .animate(_enterCurve),
              child: FadeTransition(opacity: _enterCurve, child: _rail(hz)),
            );
            final content = Expanded(child: _contentPane());
            final divV = VerticalDivider(
                width: 1,
                color: Colors.white.withOpacity(t.isDark ? 0.08 : 0.3));
            final divH = Divider(
                height: 1,
                color: Colors.white.withOpacity(t.isDark ? 0.08 : 0.3));
            switch (pos) {
              case 1:
                return Row(children: [content, divV, rail]);
              case 2:
                return Column(children: [rail, divH, content]);
              case 3:
                return Column(children: [content, divH, rail]);
              default:
                return Row(children: [rail, divV, content]);
            }
          },
        );
      },
    );
  }

  Widget _contentPane() => SlideTransition(
        position:
            Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
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
      );

  Widget _rail(bool hz) => ValueListenableBuilder<bool>(
        valueListenable: UiSettings.compactSidebar,
        builder: (ctx, compact, _) => ClipRect(
          child: UiSettings.realBlur.value
              ? BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: _railBody(compact, hz),
                )
              : _railBody(compact, hz),
        ),
      );

  Widget _railBody(bool compact, bool hz) => AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: hz ? double.infinity : (compact ? sc(60) : sc(190)),
        height: hz ? (compact ? sc(56) : sc(68)) : double.infinity,
        color: (t.isDark ? const Color(0xFF0B0E14) : Colors.white)
            .withOpacity(t.isDark ? 0.35 : 0.5),
        child: LayoutBuilder(
          builder: (ctx, c) => hz
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: c.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _cats.length; i++) ...[
                          if (i > 0) SizedBox(width: sc(6)),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: sc(8)),
                            child: _catBtn(i, true),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _cats.length; i++) ...[
                            if (i > 0) SizedBox(height: sc(6)),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: compact ? sc(8) : sc(10)),
                              child: _catBtn(i, compact),
                            ),
                          ],
                        ],
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
      case 7:
        return _presets();
      default:
        return _about();
    }
  }

  Widget _catBtn(int i, bool compact) {
    final active = _cat == i;
    final btn = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SoundService.click();
        _goCat(i);
      },
      child: AnimatedContainer(
        duration: t.animDur,
        curve: t.animCurve,
        padding: EdgeInsets.symmetric(
            horizontal: compact ? sc(10) : sc(12), vertical: sc(10)),
        decoration: BoxDecoration(
          color: active ? t.accent.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: active ? t.accent.withOpacity(0.5) : Colors.transparent),
        ),
        child: compact
            ? Center(
                child: Icon(_cats[i][0] as IconData,
                    size: sc(16),
                    color: active ? t.accent : t.text.withOpacity(0.5)),
              )
            : Row(children: [
                Icon(_cats[i][0] as IconData,
                    size: sc(16),
                    color: active ? t.accent : t.text.withOpacity(0.5)),
                SizedBox(width: sc(10)),
                Flexible(
                  child: Text(
                      tr(_cats[i][1] as String, _cats[i][2] as String),
                      style: TextStyle(
                          fontSize: sc(12),
                          fontWeight: FontWeight.w700,
                          color: active ? t.text : t.text.withOpacity(0.6)),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
      ),
    );
    return compact
        ? Tooltip(
            message: tr(_cats[i][1] as String, _cats[i][2] as String),
            preferBelow: false,
            waitDuration: const Duration(milliseconds: 350),
            child: btn,
          )
        : btn;
  }

  Widget _presetsList() {
    final all = <Preset>[...BuiltinPresets.all, ...UiSettings.userPresets];
    if (all.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: sc(8)),
        child: Text(tr('Нет пресетов', 'No presets'),
            style:
                TextStyle(fontSize: 12, color: t.text.withOpacity(0.5))),
      );
    }
    return Column(children: [
      for (var i = 0; i < all.length; i++) ...[
        if (i > 0) SizedBox(height: sc(6)),
        _presetRow(all[i]),
      ],
    ]);
  }

  Widget _presetRow(Preset p) {
    final active = UiSettings.appliedPresetId.value == p.id;
    final gpu = p.data['rblur'] == true;
    return Container(
      padding: EdgeInsets.all(sc(10)),
      decoration: BoxDecoration(
        color: active ? t.accent.withOpacity(0.10) : t.card.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? t.accent.withOpacity(0.6)
              : Colors.white.withOpacity(t.isDark ? 0.08 : 0.3),
        ),
      ),
      child: Row(children: [
        Container(
          width: sc(32),
          height: sc(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: p.data['grad'] == true
                ? LinearGradient(colors: [
                    p.data['accent'] != null
                        ? Color(p.data['accent'] as int)
                        : t.accent,
                    p.data['accent2'] != null
                        ? Color(p.data['accent2'] as int)
                        : t.accent,
                  ])
                : null,
            color: p.data['grad'] == true
                ? null
                : (p.data['accent'] != null
                    ? Color(p.data['accent'] as int)
                    : t.accent),
            border: Border.all(color: t.accent.withOpacity(0.4)),
          ),
          child: Icon(active ? Icons.check_rounded : Icons.style_rounded,
              size: sc(14), color: Colors.white.withOpacity(0.9)),
        ),
        SizedBox(width: sc(10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(
                  child: Text(p.name,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: active ? t.accent : t.text),
                      overflow: TextOverflow.ellipsis),
                ),
                if (p.builtin) ...[
                  SizedBox(width: sc(6)),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: sc(6), vertical: sc(2)),
                    decoration: BoxDecoration(
                      color: t.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: t.accent.withOpacity(0.3)),
                    ),
                    child: Text(tr('ВСТРОЕН.', 'BUILTIN'),
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: t.accent,
                            letterSpacing: 0.5)),
                  ),
                ],
                if (active) ...[
                  SizedBox(width: sc(6)),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: sc(6), vertical: sc(2)),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: const Color(0xFF22C55E).withOpacity(0.4)),
                    ),
                    child: Text(tr('АКТИВЕН', 'ACTIVE'),
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF22C55E),
                            letterSpacing: 0.5)),
                  ),
                ],
                if (gpu) ...[
                  SizedBox(width: sc(6)),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: sc(6), vertical: sc(2)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB020).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: const Color(0xFFFFB020).withOpacity(0.4)),
                    ),
                    child: Text('⚠ GPU',
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFFFB020),
                            letterSpacing: 0.5)),
                  ),
                ],
              ]),
              if (p.description.isNotEmpty || gpu)
                Text(
                  gpu
                      ? '${p.description.isNotEmpty ? '${p.description} · ' : ''}⚠ ${tr('Высокая нагрузка GPU', 'High GPU load')}'
                      : p.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 10,
                      color: gpu
                          ? const Color(0xFFFFB020)
                          : t.text.withOpacity(0.55),
                      height: 1.4),
                ),
            ],
          ),
        ),
        SizedBox(width: sc(6)),
        _iconBtn(Icons.play_arrow_rounded, () {
          SoundService.toggle();
          UiSettings.applyPreset(p);
          NotifyService.push(
              tr('Пресет «${p.name}» применён',
                  'Preset "${p.name}" applied'),
              icon: Icons.check_circle_rounded);
        }),
        SizedBox(width: sc(4)),
        _iconBtn(Icons.share_rounded, () async {
          final code = p.export();
          try {
            await _copyToClipboard(code);
            NotifyService.push(
                tr('Код скопирован — отправь другу',
                    'Code copied — share it'),
                icon: Icons.content_copy_rounded);
          } catch (_) {
            NotifyService.push(
                tr('Не удалось скопировать', 'Copy failed'),
                icon: Icons.error_outline_rounded,
                soundEvent: 'error');
          }
        }),
        if (!p.builtin) ...[
          SizedBox(width: sc(4)),
          _iconBtn(Icons.delete_outline_rounded, () {
            UiSettings.removePreset(p.id);
            setState(() {});
            NotifyService.push(tr('Удалено', 'Deleted'),
                icon: Icons.delete_rounded);
          }),
        ],
      ]),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<String?> _prompt(
      {required String title,
      required String hint,
      String? initial,
      bool multiline = false}) async {
    final c = TextEditingController(text: initial ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(sc(20)),
          child: Container(
            width: 400,
            padding: EdgeInsets.all(sc(20)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  t.accent.withOpacity(0.12),
                  (t.isDark ? const Color(0xFF0B0E14) : Colors.white)
                      .withOpacity(t.isDark ? 0.92 : 0.96),
                ],
              ),
              borderRadius: BorderRadius.circular(sc(20)),
              border: Border.all(color: t.accent.withOpacity(0.35)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 40,
                    offset: const Offset(0, 16)),
                BoxShadow(color: t.accent.withOpacity(0.12), blurRadius: 24),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Icon(Icons.style_rounded, size: sc(16), color: t.accent),
                SizedBox(width: sc(8)),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontSize: sc(14),
                          fontWeight: FontWeight.w800,
                          color: t.text)),
                ),
              ]),
              SizedBox(height: sc(12)),
              Container(
                decoration: BoxDecoration(
                  color:
                      Colors.black.withOpacity(t.isDark ? 0.35 : 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.accent.withOpacity(0.4)),
                ),
                child: TextField(
                  controller: c,
                  maxLines: multiline ? 4 : 1,
                  autofocus: true,
                  style: TextStyle(color: t.text, fontSize: 12),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: TextStyle(
                        color: t.text.withOpacity(0.35), fontSize: 11),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: sc(12), vertical: sc(10)),
                  ),
                ),
              ),
              SizedBox(height: sc(14)),
              Row(children: [
                Expanded(
                  child: Btn25D(
                    base: t.surface,
                    radius: 999,
                    onTap: () => Navigator.pop(ctx, false),
                    padding: EdgeInsets.symmetric(vertical: sc(10)),
                    child: Center(
                      child: Text(tr('Отмена', 'Cancel'),
                          style: TextStyle(
                              fontSize: sc(12),
                              color: t.text.withOpacity(0.7),
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                SizedBox(width: sc(10)),
                Expanded(
                  child: Btn25D(
                    base: t.accent,
                    radius: 999,
                    onTap: () => Navigator.pop(ctx, true),
                    padding: EdgeInsets.symmetric(vertical: sc(10)),
                    child: Center(
                      child: Text(tr('ОК', 'OK'),
                          style: TextStyle(
                              fontSize: sc(12),
                              color: t.buttonTextColor,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
    return ok == true ? c.text.trim() : null;
  }

  Future<void> _saveCurrent() async {
    final id = UiSettings.appliedPresetId.value;
    final idx =
        id == null ? -1 : UiSettings.userPresets.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      final old = UiSettings.userPresets[idx];
      UiSettings.updatePreset(old.id, UiSettings.presetSnapshot());
      setState(() {});
      NotifyService.push(
          tr('Пресет «${old.name}» обновлён', 'Preset "${old.name}" updated'),
          icon: Icons.save_rounded);
      return;
    }
    final name = await _prompt(
      title: tr('Название пресета', 'Preset name'),
      hint: tr('Например: My Vibe', 'e.g. My Vibe'),
    );
    if (name == null || name.isEmpty) return;
    final desc = await _prompt(
      title: tr('Описание (необязательно)', 'Description (optional)'),
      hint: tr('Пару слов о вайбе', 'A few words about the vibe'),
    );
    UiSettings.createUserPreset(name, desc ?? '');
    setState(() {});
    NotifyService.push(
        tr('Пресет «$name» сохранён', 'Preset "$name" saved'),
        icon: Icons.save_rounded);
  }

  Future<void> _importPreset() async {
    final code = await _prompt(
      title: tr('Вставь код пресета', 'Paste preset code'),
      hint: 'z2m:v1:...',
      multiline: true,
    );
    if (code == null || code.isEmpty) return;
    final p = UiSettings.importFromString(code);
    if (p == null) {
      NotifyService.push(tr('Невалидный код', 'Invalid code'),
          icon: Icons.error_outline_rounded, soundEvent: 'error');
      return;
    }
    setState(() {});
    NotifyService.push(tr('Импортирован «${p.name}»', 'Imported "${p.name}"'),
        icon: Icons.download_done_rounded);
  }

  Future<void> _exportCurrent() async {
    final name = await _prompt(
      title: tr('Имя для шейр-кода', 'Name for share'),
      hint: tr('Как его увидят другие', 'How others will see it'),
      initial: tr('Мой пресет', 'My preset'),
    );
    if (name == null || name.isEmpty) return;
    final desc = await _prompt(
      title: tr('Описание', 'Description'),
      hint: tr('Кратко', 'Short'),
    );
    final code = UiSettings.exportCurrent(name, desc ?? '');
    try {
      await _copyToClipboard(code);
      NotifyService.push(tr('Шейр-код скопирован', 'Share code copied'),
          icon: Icons.content_copy_rounded);
    } catch (_) {
      NotifyService.push(tr('Не удалось скопировать', 'Copy failed'),
          icon: Icons.error_outline_rounded, soundEvent: 'error');
    }
  }

  Widget _presets() => _col([
        _card(
            title: tr('Мои пресеты', 'My presets'),
            icon: Icons.bookmark_rounded,
            children: [
              Text(
                tr(
                    'Полный снимок темы: цвета, блюр, радиусы, шрифт, фон, анимации. Сохраняй, импортируй коды друзей, делись своими.',
                    'Full theme snapshot: colors, blur, radius, font, background, animations. Save, import friends\' codes, share yours.'),
                style: TextStyle(
                    fontSize: 11, color: t.text.withOpacity(0.55)),
              ),
              SizedBox(height: sc(8)),
              Row(children: [
                Expanded(
                    child: Btn25D(
                  base: t.accent,
                  radius: 999,
                  onTap: _saveCurrent,
                  padding: EdgeInsets.symmetric(vertical: sc(9)),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_rounded,
                            size: sc(14), color: t.buttonTextColor),
                        SizedBox(width: sc(6)),
                        Text(tr('Сохранить', 'Save'),
                            style: TextStyle(
                                fontSize: sc(11),
                                color: t.buttonTextColor,
                                fontWeight: FontWeight.w700)),
                      ]),
                )),
                SizedBox(width: sc(8)),
                Expanded(
                    child: Btn25D(
                  base: t.surface,
                  radius: 999,
                  onTap: _importPreset,
                  padding: EdgeInsets.symmetric(vertical: sc(9)),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_rounded,
                            size: sc(14), color: t.accent),
                        SizedBox(width: sc(6)),
                        Text(tr('Импорт', 'Import'),
                            style: TextStyle(
                                fontSize: sc(11),
                                color: t.text,
                                fontWeight: FontWeight.w700)),
                      ]),
                )),
                SizedBox(width: sc(8)),
                Expanded(
                    child: Btn25D(
                  base: t.surface,
                  radius: 999,
                  onTap: _exportCurrent,
                  padding: EdgeInsets.symmetric(vertical: sc(9)),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share_rounded,
                            size: sc(14), color: t.accent),
                        SizedBox(width: sc(6)),
                        Text(tr('Шейр', 'Share'),
                            style: TextStyle(
                                fontSize: sc(11),
                                color: t.text,
                                fontWeight: FontWeight.w700)),
                      ]),
                )),
              ]),
              SizedBox(height: sc(12)),
              _presetsList(),
            ]),
      ]);

  Widget _appearance() => _col([
        _card(
            title: tr('Тема', 'Theme'),
            icon: Icons.palette_rounded,
            children: [
              _themeSwitch(),
              _sep(),
              _switch(tr('Авто-тема (ночью тёмная)', 'Auto theme'),
                  UiSettings.autoTheme.value, () {
                UiSettings.autoTheme.value = !UiSettings.autoTheme.value;
                UiSettings.save();
              }, icon: Icons.schedule_rounded),
              if (UiSettings.autoTheme.value) ...[
                _sep(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: sc(14)),
                  child: Row(children: [
                    Icon(Icons.dark_mode_rounded,
                        size: 16, color: t.accent),
                    SizedBox(width: sc(8)),
                    Expanded(
                      child: Text(tr('Тёмная с', 'Dark from'),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: t.text)),
                    ),
                    _TimeWheel(
                      theme: t,
                      value: UiSettings.themeFrom.value,
                      on: (v) {
                        UiSettings.themeFrom.value = v;
                        UiSettings.save();
                      },
                    ),
                    SizedBox(width: sc(8)),
                    Text(tr('до', 'to'),
                        style: TextStyle(
                            fontSize: 12, color: t.text.withOpacity(0.6))),
                    SizedBox(width: sc(8)),
                    _TimeWheel(
                      theme: t,
                      value: UiSettings.themeTo.value,
                      on: (v) {
                        UiSettings.themeTo.value = v;
                        UiSettings.save();
                      },
                    ),
                  ]),
                ),
              ],
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
                    UiSettings.accent2.value ?? const Color(0xFF22D3EE),
                    (c) {
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
        // ✨ НОВАЯ КАРТОЧКА: Фишки (часы, хоткеи, стиль тостов)
        _card(
            title: tr('Фишки', 'Features'),
            icon: Icons.auto_awesome_rounded,
            children: [
              _switch(tr('Часы сверху', 'Top clock'),
                  UiSettings.clockOn.value, () {
                UiSettings.clockOn.value = !UiSettings.clockOn.value;
                UiSettings.save();
              }, icon: Icons.schedule_rounded),
              _sep(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: sc(4)),
                child: Row(children: [
                  Icon(Icons.notifications_rounded,
                      size: sc(14), color: t.accent),
                  SizedBox(width: sc(8)),
                  Expanded(
                      child: Text(tr('Стиль тостов', 'Toast style'),
                          style: TextStyle(
                              fontSize: sc(11),
                              fontWeight: FontWeight.w600,
                              color: t.text))),
                  for (var i = 0; i < 3; i++) ...[
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        UiSettings.toastStyle.value = i;
                        UiSettings.save();
                      },
                      child: AnimatedContainer(
                        duration: t.animDur,
                        curve: t.animCurve,
                        padding: EdgeInsets.symmetric(
                            horizontal: sc(8), vertical: sc(4)),
                        decoration: BoxDecoration(
                          color: UiSettings.toastStyle.value == i
                              ? t.accent.withOpacity(0.8)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: UiSettings.toastStyle.value == i
                                  ? t.accent
                                  : t.text.withOpacity(0.15)),
                        ),
                        child: Text(
                            [
                              tr('Стекло', 'Glass'),
                              tr('Неон', 'Neon'),
                              tr('Минимал', 'Minimal')
                            ][i],
                            style: TextStyle(
                                fontSize: sc(9),
                                fontWeight: FontWeight.w700,
                                color: UiSettings.toastStyle.value == i
                                    ? t.buttonTextColor
                                    : t.text.withOpacity(0.6))),
                      ),
                    ),
                    if (i < 2) SizedBox(width: sc(6)),
                  ],
                ]),
              ),
            ]),
        _gap(),
        _card(
            title: tr('Интерфейс', 'Interface'),
            icon: Icons.dashboard_customize_rounded,
            children: [
              _slider(tr('Масштаб', 'Scale'), UiSettings.uiScale.value, 0.7,
                  1.6, (v) {
                UiSettings.uiScale.value = v;
                UiScale.value = v;
                UiSettings.save();
              },
                  suffix: '${(UiSettings.uiScale.value * 100).toInt()}%',
                  factor: 100),
              _sep(),
              _slider(tr('Скругление', 'Radius'),
                  UiSettings.glassRadius.value, 8, 48, (v) {
                UiSettings.glassRadius.value = v;
                UiSettings.save();
              }),
              _sep(),
              Row(children: [
                Icon(Icons.flip_to_front_rounded,
                    size: 18, color: t.accent),
                SizedBox(width: 10),
                Expanded(
                  child: Text(tr('Сайдбар', 'Sidebar'),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: t.text)),
                ),
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) SizedBox(width: sc(4)),
                  _posChip(i),
                ],
              ]),
              _sep(),
              _switch(tr('Компактный сайдбар', 'Compact sidebar'),
                  UiSettings.compactSidebar.value, () {
                UiSettings.compactSidebar.value =
                    !UiSettings.compactSidebar.value;
                UiSettings.save();
              }, icon: Icons.unfold_less_rounded),
              _sep(),
              Row(children: [
                _chip(tr('Системный шрифт', 'System'),
                    UiSettings.fontMode.value == 0, () {
                  UiSettings.fontMode.value = 0;
                  UiSettings.save();
                }),
                SizedBox(width: sc(8)),
                _chip(tr('Моно', 'Mono'),
                    UiSettings.fontMode.value == 1, () {
                  UiSettings.fontMode.value = 1;
                  UiSettings.save();
                }),
              ]),
            ]),
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
                  controller: TextEditingController(
                      text: UiSettings.bootCaption.value),
                  onSubmitted: (s) {
                    UiSettings.bootCaption.value = s;
                    UiSettings.save();
                  },
                  style: TextStyle(color: t.text, fontSize: 12),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.title_rounded,
                        size: 14, color: t.accent),
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
              _sep(),
              _switch(tr('Ripple по клику', 'Click ripple'),
                  UiSettings.rippleFx.value, () {
                UiSettings.rippleFx.value = !UiSettings.rippleFx.value;
                UiSettings.save();
              }, icon: Icons.touch_app_rounded),
            ]),
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
              if (UiSettings.realBlur.value) ...[
                Padding(
                  padding: EdgeInsets.only(top: sc(6)),
                  child: Row(children: [
                    Icon(Icons.warning_amber_rounded,
                        size: sc(14), color: const Color(0xFFFFB020)),
                    SizedBox(width: sc(6)),
                    Text(
                        tr('Высокая нагрузка GPU', 'High GPU load'),
                        style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFFFFB020),
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
              _sep(),
              _slider(tr('Размытие', 'Blur'), UiSettings.blurSigma.value, 0,
                  50, (v) {
                UiSettings.blurSigma.value = v;
                UiSettings.save();
              }),
              _sep(),
              _slider(tr('Насыщенность', 'Saturation'),
                  UiSettings.saturation.value, 1.0, 2.0, (v) {
                UiSettings.saturation.value = v;
                UiSettings.save();
              },
                  suffix:
                      UiSettings.saturation.value.toStringAsFixed(2)),
              _sep(),
              _slider(tr('Прозрачность', 'Opacity'),
                  UiSettings.glassOpacity.value, 0.0, 0.8, (v) {
                UiSettings.glassOpacity.value = v;
                UiSettings.save();
              },
                  suffix:
                      UiSettings.glassOpacity.value.toStringAsFixed(2)),
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
              },
                  suffix:
                      UiSettings.edgeGlow.value.toStringAsFixed(2)),
              _sep(),
              _slider(tr('Граница', 'Border'),
                  UiSettings.borderOpacity.value, 0, 0.6, (v) {
                UiSettings.borderOpacity.value = v;
                UiSettings.save();
              },
                  suffix:
                      UiSettings.borderOpacity.value.toStringAsFixed(2)),
              _sep(),
              _slider(tr('Верхний блик', 'Specular'),
                  UiSettings.specular.value, 0, 1, (v) {
                UiSettings.specular.value = v;
                UiSettings.save();
              },
                  suffix:
                      UiSettings.specular.value.toStringAsFixed(2)),
              // ✨ СВИП-БЛИК ПО КАРТОЧКАМ
                            _sep(),
              _switch(tr('Свечение курсора', 'Cursor glow'),
                  UiSettings.cursorGlow.value, () {
                UiSettings.cursorGlow.value = !UiSettings.cursorGlow.value;
                UiSettings.save();
              }, icon: Icons.highlight_alt_rounded),
              _sep(),
              _switch(tr('Свип-блик по карточкам', 'Card light sweep'),
                  UiSettings.sweepFx.value, () {
                UiSettings.sweepFx.value = !UiSettings.sweepFx.value;
                UiSettings.save();
              }, icon: Icons.flare_rounded),
              _sep(),
              _switch(tr('Пульс от кнопок старта/стопа', 'Pulse from start/stop'),
                  UiSettings.pulseFx.value, () {
                UiSettings.pulseFx.value = !UiSettings.pulseFx.value;
                UiSettings.save();
              }, icon: Icons.bolt_rounded),
            ]),
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
              _bgCurrentChip(),
              _sep(),
              Btn25D(
                base: t.surface,
                radius: 999,
                onTap: _pickBgImage,
                padding: EdgeInsets.symmetric(vertical: sc(9)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_rounded,
                        size: sc(14), color: t.accent),
                    SizedBox(width: sc(6)),
                    Flexible(
                      child: Text(
                        UiSettings.bgImagePath.value == null
                            ? tr('Выбрать свою картинку', 'Pick your image')
                            : UiSettings.bgImagePath.value!
                                .replaceAll('\\', '/')
                                .split('/')
                                .last,
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
            ]),
        _gap(),
        _card(
            title: tr('Настройка', 'Tuning'),
            icon: Icons.speed_rounded,
            children: [
              if (UiSettings.bgStyle.value != 47) ...[
                _slider(tr('Скорость фона', 'Background speed'),
                    UiSettings.auroraSpeed.value, 0.3, 3.0, (v) {
                  UiSettings.auroraSpeed.value = v;
                  UiSettings.save();
                },
                    suffix:
                        'x${UiSettings.auroraSpeed.value.toStringAsFixed(1)}'),
                _sep(),
                _slider(tr('Плотность фона', 'Background density'),
                    UiSettings.bgDensity.value, 0.4, 2.0, (v) {
                  UiSettings.bgDensity.value = v;
                  UiSettings.save();
                },
                    suffix:
                        'x${UiSettings.bgDensity.value.toStringAsFixed(1)}'),
                _sep(),
              ],
              _slider(tr('Виньетка', 'Vignette'), UiSettings.vignette.value,
                  0.0, 0.8, (v) {
                UiSettings.vignette.value = v;
                UiSettings.save();
              },
                  suffix:
                      UiSettings.vignette.value.toStringAsFixed(2)),
              if (UiSettings.bgStyle.value != 47) ...[
                _sep(),
                _switch(tr('Параллакс', 'Parallax'),
                    UiSettings.parallax.value, () {
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
              ],
            ]),
      ]);

  Widget _bgCurrentChip() => ValueListenableBuilder<int>(
        valueListenable: UiSettings.bgStyle,
        builder: (ctx, cur, _) {
          final e = _bgStyles[cur.clamp(0, _bgStyles.length - 1)];
          return Listener(
            onPointerSignal: (ev) {
              if (ev is PointerScrollEvent) {
                final dir = ev.scrollDelta.dy > 0 ? 1 : -1;
                final next =
                    (cur + dir + _bgStyles.length) % _bgStyles.length;
                UiSettings.bgStyle.value = next;
                UiSettings.save();
                SoundService.toggle();
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openBgDialog(),
              child: AnimatedContainer(
                duration: t.animDur,
                curve: t.animCurve,
                padding: EdgeInsets.symmetric(
                    horizontal: sc(14), vertical: sc(12)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    t.accent.withOpacity(0.20),
                    t.accent.withOpacity(0.08),
                  ]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: t.accent.withOpacity(0.5)),
                ),
                child: Row(children: [
                  Container(
                    width: sc(36),
                    height: sc(36),
                    decoration: BoxDecoration(
                      color:
                          Colors.black.withOpacity(t.isDark ? 0.4 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: t.accent.withOpacity(0.4)),
                    ),
                    child: Icon(e[0] as IconData,
                        size: sc(18), color: t.accent),
                  ),
                  SizedBox(width: sc(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr(e[1] as String, e[2] as String),
                            style: TextStyle(
                                fontSize: sc(13),
                                fontWeight: FontWeight.w800,
                                color: t.text)),
                        Text(
                            tr('Крути колёсиком или нажми для списка',
                                'Scroll or tap for gallery'),
                            style: TextStyle(
                                fontSize: sc(10),
                                color: t.text.withOpacity(0.6))),
                      ],
                    ),
                  ),
                  Icon(Icons.unfold_more_rounded,
                      size: sc(18), color: t.accent),
                ]),
              ),
            ),
          );
        },
      );

  void _openBgDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _BgGalleryDialog(theme: t),
    );
  }

  Future<void> _pickBgImage() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.image);
    if (picked == null || picked.files.isEmpty) return;
    final p = picked.files.first.path;
    if (p == null) return;
    UiSettings.bgImagePath.value = p;
    UiSettings.bgStyle.value = 47;
    UiSettings.save();
    setState(() {});
    SoundService.toggle();
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
                builder: (ctx, v, _) => _slider(
                    tr('Громкость', 'Volume'), v, 0.0, 1.0, (x) {
                  UiSettings.soundVolume.value = x;
                  UiSettings.save();
                },
                    suffix: '${(v * 100).toInt()}%',
                    factor: 100),
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
                padding: EdgeInsets.symmetric(
                    horizontal: sc(12), vertical: sc(9)),
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
                'start', 'stop', 'restart', 'click', 'toggle',
                'on', 'off', 'notify', 'update', 'complete', 'error',
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
        padding:
            EdgeInsets.symmetric(horizontal: sc(10), vertical: sc(6)),
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
              ],
            ),
          ),
          _iconBtn(Icons.play_arrow_rounded,
              () => SoundService.preview(event),
              click: false),
          SizedBox(width: sc(6)),
          _iconBtn(Icons.folder_open_rounded, () async {
            final picked = await FilePicker.platform
                .pickFiles(type: FileType.audio);
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

  Widget _graphics() => _col([
        _card(
            title: tr('Производительность', 'Performance'),
            icon: Icons.monitor_rounded,
            children: [
              Row(children: [
                for (final v in [12, 24, 30, 60]) ...[
                  if (v != 12) SizedBox(width: sc(6)),
                  _chip('$v FPS', UiSettings.fpsCap.value == v, () {
                    UiSettings.fpsCap.value = v;
                    UiSettings.save();
                  }),
                ],
              ]),
              _sep(),
              _switch(tr('Эко-режим', 'Eco mode'),
                  UiSettings.ecoMode.value, () {
                UiSettings.ecoMode.value = !UiSettings.ecoMode.value;
                UiSettings.save();
              }, icon: Icons.eco_rounded),
              _sep(),
              _switch(tr('Тени карточек', 'Card shadows'),
                  UiSettings.cardShadows.value, () {
                UiSettings.cardShadows.value = !UiSettings.cardShadows.value;
                UiSettings.save();
              }, icon: Icons.layers_rounded),
            ]),
      ]);

  Widget _about() => _col([
        Container(
          width: double.infinity,
          padding:
              EdgeInsets.symmetric(vertical: sc(26), horizontal: sc(16)),
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
            GestureDetector(
              onTap: _logoTap,
              child: Container(
                width: sc(68),
                height: sc(68),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: t.accent.withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: t.accent.withOpacity(0.4),
                        blurRadius: sc(26)),
                  ],
                ),
                child: ClipOval(
                    child:
                        Image.asset('assets/z2m_black_logo_256.png')),
              ),
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
              padding: EdgeInsets.symmetric(
                  horizontal: sc(12), vertical: sc(5)),
              decoration: BoxDecoration(
                color: t.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: t.accent.withOpacity(0.4)),
              ),
              child: Text(
                  'v${UpdateService.currentVersion} · Liquid Glass Edition',
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
                    color: t.text.withOpacity(0.55))),
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
                  UiSettings.closeToTray.value =
                      !UiSettings.closeToTray.value;
                  UiSettings.save();
                }, icon: Icons.system_security_update_rounded),
                _sep(),
                _switch(tr('Окно поверх всех', 'Always on top'),
                    UiSettings.alwaysOnTop.value, () {
                  UiSettings.alwaysOnTop.value =
                      !UiSettings.alwaysOnTop.value;
                  UiSettings.save();
                  windowManager.setAlwaysOnTop(
                      UiSettings.alwaysOnTop.value);
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
                          UiSettings.zapretPath.value ??
                              r'C:\zapret_programm',
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
                      Icon(Icons.code_rounded,
                          size: sc(14), color: t.accent),
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
                    final dir =
                        '${Platform.environment['APPDATA']}\\Z2Mini';
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
    NotifyService.push(
        tr('Папка Zapret сохранена', 'Zapret folder saved'),
        icon: Icons.folder_rounded);
  }

  void _logoTap() {
    _logoTaps++;
    _logoTimer?.cancel();
    _logoTimer = Timer(const Duration(seconds: 2), () => _logoTaps = 0);
    if (_logoTaps >= 5) {
      _logoTaps = 0;
      SoundService.play('complete');
      showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (c) => const _EasterEggDialog(),
      );
    }
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

  Widget _col(List<Widget> c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: c,
      );

  Widget _card(
          {String? title,
          IconData? icon,
          required List<Widget> children}) =>
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
        padding:
            EdgeInsets.symmetric(horizontal: sc(14), vertical: sc(4)),
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
            child: Text(label,
                style: TextStyle(fontSize: 12, color: t.text)),
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

  Widget _posChip(int i) {
    final active = UiSettings.sidebarPos.value == i;
    const ics = [
      Icons.chevron_left_rounded,
      Icons.chevron_right_rounded,
      Icons.keyboard_arrow_up_rounded,
      Icons.keyboard_arrow_down_rounded,
    ];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SoundService.toggle();
        UiSettings.sidebarPos.value = i;
        UiSettings.save();
      },
      child: AnimatedContainer(
        duration: t.animDur,
        curve: t.animCurve,
        width: sc(30),
        height: sc(30),
        decoration: BoxDecoration(
          color: active
              ? t.accent.withOpacity(0.8)
              : t.card.withOpacity(0.5),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
              color: active
                  ? t.accent
                  : Colors.white.withOpacity(t.isDark ? 0.10 : 0.5)),
        ),
        child: Icon(ics[i],
            size: sc(16),
            color: active ? t.buttonTextColor : t.text.withOpacity(0.6)),
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: () {
          SoundService.toggle();
          onTap();
        },
        child: AnimatedContainer(
          duration: t.animDur,
          curve: t.animCurve,
          padding: EdgeInsets.symmetric(
              horizontal: sc(16), vertical: sc(9)),
          decoration: BoxDecoration(
            color: active
                ? t.accent.withOpacity(0.8)
                : t.card.withOpacity(0.5),
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
          padding: EdgeInsets.symmetric(
              horizontal: sc(14), vertical: sc(9)),
          child: Row(children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: current,
                shape: BoxShape.circle,
                border:
                    Border.all(color: Colors.white.withOpacity(0.25)),
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
                color:
                    Colors.white.withOpacity(t.isDark ? 0.10 : 0.5)),
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

  static const List<List<Object>> _bgStyles = [
    [Icons.cloud_rounded, 'Аврора', 'Aurora', 0],
    [Icons.waves_rounded, 'Волны', 'Waves', 0],
    [Icons.nightlight_rounded, 'Звёзды', 'Stars', 0],
    [Icons.flashlight_on_rounded, 'Моя волна', 'My Wave', 0],
    [Icons.filter_drama_rounded, 'Облака', 'Clouds', 0],
    [Icons.sailing_rounded, 'Утки', 'Ducks', 0],
    [Icons.pets_rounded, 'Лягушки', 'Frogs', 0],
    [Icons.grid_on_rounded, 'Точки', 'Dots', 0],
    [Icons.opacity_rounded, 'Аквариум', 'Aquarium', 0],
    [Icons.cloud_queue_rounded, 'Туманность', 'Nebula', 1],
    [Icons.blur_circular_rounded, 'Чёрная дыра', 'BlackHole', 1],
    [Icons.rocket_launch_rounded, 'Комета', 'Comet', 1],
    [Icons.flash_on_rounded, 'Метеоры', 'Meteors', 1],
    [Icons.public_rounded, 'Орбиты', 'Orbits', 1],
    [Icons.brightness_2_rounded, 'Луна', 'Moon', 1],
    [Icons.auto_awesome_rounded, 'Звёздная пыль', 'Star Dust', 1],
    [Icons.wb_twilight_rounded, 'Светлячки', 'Fireflies', 2],
    [Icons.eco_rounded, 'Листопад', 'Leaves', 2],
    [Icons.local_florist_rounded, 'Сакура', 'Sakura', 2],
    [Icons.ac_unit_rounded, 'Снег', 'Snow', 2],
    [Icons.grain_rounded, 'Дождь', 'Rain', 2],
    [Icons.water_drop_rounded, 'Капли', 'Drops', 2],
    [Icons.air_rounded, 'Дым', 'Smoke', 2],
    [Icons.wb_sunny_rounded, 'Пыль в луче', 'Dust', 2],
    [Icons.blur_on_rounded, 'Лава-лампа', 'Lava', 2],
    [Icons.code_rounded, 'Матрица', 'Matrix', 3],
    [Icons.grid_4x4_rounded, 'Синтвейв', 'Synthwave', 3],
    [Icons.tv_rounded, 'CRT', 'CRT', 3],
    [Icons.terminal_rounded, 'Терминал', 'Terminal', 3],
    [Icons.radar_rounded, 'Радар', 'Radar', 3],
    [Icons.show_chart_rounded, 'Осциллограф', 'Scope', 3],
    [Icons.videocam_rounded, 'VHS', 'VHS', 3],
    [Icons.view_module_rounded, 'Пиксели', 'Pixels', 3],
    [Icons.insights_rounded, 'Ленты', 'Ribbons', 4],
    [Icons.change_circle_rounded, 'Калейдоскоп', 'Kaleido', 4],
    [Icons.filter_vintage_rounded, 'Мандала', 'Mandala', 4],
    [Icons.terrain_rounded, 'Изолинии', 'Topo', 4],
    [Icons.hexagon_rounded, 'Соты', 'Hex', 4],
    [Icons.circle_outlined, 'Пульсар', 'Pulsar', 4],
    [Icons.diamond_rounded, 'Вороной', 'Voronoi', 4],
    [Icons.bubble_chart_rounded, 'Пузыри', 'Bubbles', 4],
    [Icons.location_city_rounded, 'Город', 'City', 5],
    [Icons.lightbulb_rounded, 'Неон', 'Neon', 5],
    [Icons.local_fire_department_rounded, 'Камин', 'Fireplace', 5],
    [Icons.album_rounded, 'Винил', 'Vinyl', 5],
    [Icons.celebration_rounded, 'Конфетти', 'Confetti', 5],
    [Icons.flight_rounded, 'Самолётики', 'Planes', 5],
    [Icons.image_rounded, 'Моя картинка', 'My Image', 5],
  ];
}

class _TimeWheel extends StatefulWidget {
  final AppTheme theme;
  final int value;
  final ValueChanged<int> on;
  const _TimeWheel({
    required this.theme,
    required this.value,
    required this.on,
  });
  @override
  State<_TimeWheel> createState() => _TimeWheelState();
}

class _TimeWheelState extends State<_TimeWheel> {
  int _combo = 0;
  int _last = 0;
  String _fmt(int v) =>
      '${(v ~/ 60).toString().padLeft(2, '0')}:${(v % 60).toString().padLeft(2, '0')}';
  void _wheel(double dy) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _combo = (now - _last < 250) ? _combo + 1 : 0;
    _last = now;
    final step =
        _combo < 6 ? 1 : _combo < 14 ? 5 : _combo < 26 ? 15 : 60;
    final dir = dy < 0 ? 1 : -1;
    widget.on((widget.value + dir * step + 1440) % 1440);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Listener(
      onPointerSignal: (e) {
        if (e is PointerScrollEvent) _wheel(e.scrollDelta.dy);
      },
      child: Tooltip(
        message: tr('Крути колёсико: 1 тик = 1 мин, с ускорением',
            'Scroll: 1 tick = 1 min, accelerates'),
        waitDuration: const Duration(milliseconds: 400),
        child: Container(
          padding:
              EdgeInsets.symmetric(horizontal: sc(12), vertical: sc(7)),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(t.isDark ? 0.35 : 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: t.accent.withOpacity(0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.schedule_rounded,
                size: 13, color: t.accent.withOpacity(0.8)),
            SizedBox(width: sc(6)),
            Text(_fmt(widget.value),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: t.accent)),
          ]),
        ),
      ),
    );
  }
}

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
                  border:
                      Border.all(color: widget.accent.withOpacity(0.6)),
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
                  _c.text =
                      widget.text.replaceAll(RegExp(r'[^0-9.,]'), '');
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
              color:
                  (t.isDark ? const Color(0xFF0B0E14) : Colors.white)
                      .withOpacity(t.isDark ? 0.78 : 0.88),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white
                    .withOpacity(t.isDark ? 0.15 : 0.6),
                width: 1,
              ),
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
                    color: Colors.black
                        .withOpacity(t.isDark ? 0.35 : 0.06),
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
                        border: Border.all(
                            color: Colors.white, width: 2),
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
                    border: Border.all(
                        color: Colors.white.withOpacity(0.12)),
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
                        border: Border.all(
                            color: Colors.white, width: 2),
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
                    border: Border.all(
                        color: Colors.white.withOpacity(0.12)),
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
                        border: Border.all(
                            color: Colors.white, width: 2),
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
      ((widget.value - widget.min) / (widget.max - widget.min))
          .clamp(0.0, 1.0);
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
                        color: widget.accent.withOpacity(0.9),
                        width: 2),
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

class _Conf {
  final double x, delay, speed;
  final int ci;
  _Conf(this.x, this.delay, this.speed, this.ci);
}

class _ConfPainter extends CustomPainter {
  final double t;
  final List<_Conf> parts;
  _ConfPainter(this.t, this.parts);
  static const _cols = [
    Color(0xFFB3E65C),
    Color(0xFF60A5FA),
    Color(0xFFFFD166),
    Color(0xFFEF476F),
    Color(0xFFFFFFFF),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in parts) {
      final life = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (life <= 0 || life >= 1) continue;
      final y = life * (size.height + 40) - 20;
      final x = p.x * size.width + math.sin(life * 6 + p.x * 10) * 18;
      canvas.save();
      canvas.translate(x, y * (0.6 + p.speed * 0.6));
      canvas.rotate(life * 8 + p.x * 6);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 9, height: 5),
        Paint()..color = _cols[p.ci].withOpacity(1 - life * 0.7),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfPainter old) => true;
}

class _EasterEggDialog extends StatefulWidget {
  const _EasterEggDialog();
  @override
  State<_EasterEggDialog> createState() => _EasterEggDialogState();
}

class _EasterEggDialogState extends State<_EasterEggDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2600));
  late final List<_Conf> _parts = [
    for (var i = 0; i < 90; i++)
      _Conf(
        math.Random(i).nextDouble(),
        math.Random(i + 90).nextDouble() * 0.3,
        math.Random(i + 180).nextDouble(),
        i % 5,
      )
  ];

  @override
  void initState() {
    super.initState();
    _c.forward();
    Future.delayed(const Duration(milliseconds: 2700), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        child: IgnorePointer(
          child: Stack(children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _c,
                builder: (ctx, _) =>
                    CustomPaint(painter: _ConfPainter(_c.value, _parts)),
              ),
            ),
            Center(
              child: AnimatedOpacity(
                opacity: _c.value < 0.85 ? 1 : (1 - _c.value) / 0.15,
                duration: const Duration(milliseconds: 120),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: sc(28), vertical: sc(20)),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.78),
                    borderRadius: BorderRadius.circular(sc(22)),
                    border: Border.all(
                      color: const Color(0xFFB3E65C).withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB3E65C).withOpacity(0.25),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child:
                      Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('🦆', style: TextStyle(fontSize: sc(40))),
                    SizedBox(height: sc(8)),
                    Text(
                      tr('Кря! Ты нашёл пасхалку!',
                          'Quack! You found the easter egg!'),
                      style: TextStyle(
                          fontSize: sc(15),
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFB3E65C)),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      );
}

class _BgGalleryDialog extends StatefulWidget {
  final AppTheme theme;
  const _BgGalleryDialog({required this.theme});
  @override
  State<_BgGalleryDialog> createState() => _BgGalleryDialogState();
}

class _BgGalleryDialogState extends State<_BgGalleryDialog> {
  int _filter = 0;
  static const _cats = [
    ['Все', 'All', Icons.apps_rounded],
    ['База', 'Base', Icons.cloud_rounded],
    ['Космос', 'Space', Icons.public_rounded],
    ['Природа', 'Nature', Icons.eco_rounded],
    ['Ретро', 'Retro', Icons.tv_rounded],
    ['Абстракция', 'Abstract', Icons.insights_rounded],
    ['Уют', 'Cozy', Icons.location_city_rounded],
  ];

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(sc(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: 720,
            height: 560,
            padding: EdgeInsets.all(sc(20)),
            decoration: BoxDecoration(
              color:
                  (t.isDark ? const Color(0xFF0B0E14) : Colors.white)
                      .withOpacity(t.isDark ? 0.92 : 0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white
                    .withOpacity(t.isDark ? 0.15 : 0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.landscape_rounded,
                      size: sc(18), color: t.accent),
                  SizedBox(width: sc(8)),
                  Text(tr('Галерея фонов', 'Background gallery'),
                      style: TextStyle(
                          fontSize: sc(16),
                          fontWeight: FontWeight.w800,
                          color: t.text)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: sc(30),
                      height: sc(30),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.close_rounded,
                          size: sc(15), color: t.text.withOpacity(0.7)),
                    ),
                  ),
                ]),
                SizedBox(height: sc(14)),
                SizedBox(
                  height: sc(32),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (var i = 0; i < _cats.length; i++) ...[
                        if (i > 0) SizedBox(width: sc(6)),
                        _filterChip(i),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: sc(14)),
                Expanded(
                  child: ValueListenableBuilder<int>(
                    valueListenable: UiSettings.bgStyle,
                    builder: (ctx, cur, _) {
                      final items = <int>[];
                      for (var i = 0;
                          i < _SettingsPageState._bgStyles.length;
                          i++) {
                        if (_filter == 0) {
                          items.add(i);
                        } else {
                          final cat = _SettingsPageState
                              ._bgStyles[i][3] as int;
                          if (cat == _filter - 1) items.add(i);
                        }
                      }
                      return GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: sc(8),
                          crossAxisSpacing: sc(8),
                          childAspectRatio: 1.4,
                        ),
                        itemCount: items.length,
                        itemBuilder: (c, idx) {
                          final i = items[idx];
                          final active = cur == i;
                          final e = _SettingsPageState._bgStyles[i];
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              SoundService.toggle();
                              UiSettings.bgStyle.value = i;
                              UiSettings.save();
                            },
                            child: AnimatedContainer(
                              duration: t.animDur,
                              curve: t.animCurve,
                              decoration: BoxDecoration(
                                color: active
                                    ? t.accent.withOpacity(0.8)
                                    : t.card.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: active
                                      ? t.accent
                                      : Colors.white.withOpacity(
                                          t.isDark ? 0.10 : 0.5),
                                  width: active ? 2 : 1,
                                ),
                              ),
                              padding: EdgeInsets.all(sc(8)),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(e[0] as IconData,
                                      size: sc(20),
                                      color: active
                                          ? t.buttonTextColor
                                          : t.text.withOpacity(0.6)),
                                  SizedBox(height: sc(4)),
                                  Text(
                                    tr(e[1] as String,
                                        e[2] as String),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: sc(9),
                                        fontWeight: FontWeight.w700,
                                        color: active
                                            ? t.buttonTextColor
                                            : t.text.withOpacity(0.6)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChip(int i) {
    final active = _filter == i;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _filter = i),
      child: AnimatedContainer(
        duration: widget.theme.animDur,
        padding:
            EdgeInsets.symmetric(horizontal: sc(12), vertical: sc(6)),
        decoration: BoxDecoration(
          color: active
              ? widget.theme.accent.withOpacity(0.8)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? widget.theme.accent
                : Colors.white.withOpacity(0.10),
          ),
        ),
        child: Row(children: [
          Icon(_cats[i][2] as IconData,
              size: sc(12),
              color: active
                  ? widget.theme.buttonTextColor
                  : widget.theme.text.withOpacity(0.7)),
          SizedBox(width: sc(4)),
          Text(tr(_cats[i][0] as String, _cats[i][1] as String),
              style: TextStyle(
                  fontSize: sc(10),
                  fontWeight: FontWeight.w700,
                  color: active
                      ? widget.theme.buttonTextColor
                      : widget.theme.text.withOpacity(0.8))),
        ]),
      ),
    );
  }
}