import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'ui_scale.dart';
import 'preset_service.dart';

class UiSettings {
  // ── интерфейс ──
  static final ValueNotifier<bool> isDark = ValueNotifier(true);
  static final ValueNotifier<String> language = ValueNotifier('RU');
  static final ValueNotifier<double> uiScale = ValueNotifier(1.0);
  static final ValueNotifier<bool> animationsEnabled = ValueNotifier(true);
  static final ValueNotifier<bool> closeToTray = ValueNotifier(true);
  static final ValueNotifier<int> sidebarPos =
      ValueNotifier(0); // 0 лево, 1 право, 2 верх, 3 низ
  static final ValueNotifier<Color?> accentColor = ValueNotifier(null);
  static final ValueNotifier<Color?> buttonColor = ValueNotifier(null);
  static final ValueNotifier<bool> autoTheme = ValueNotifier(false);
  static final ValueNotifier<int> themeFrom = ValueNotifier(19 * 60);
  static final ValueNotifier<int> themeTo = ValueNotifier(7 * 60);
  static final ValueNotifier<bool> alwaysOnTop = ValueNotifier(false);
  static final ValueNotifier<double> windowOpacity = ValueNotifier(1.0);
  static final ValueNotifier<int> fontMode = ValueNotifier(0);
  static final ValueNotifier<String?> zapretPath = ValueNotifier(null);
  static final ValueNotifier<String?> selectedConfig = ValueNotifier(null);

  // ── кастом 2а ──
  static final ValueNotifier<double> animSpeed = ValueNotifier(1.0);
  static final ValueNotifier<bool> gradientAccent = ValueNotifier(false);
  static final ValueNotifier<Color?> accent2 = ValueNotifier(null);
  static final ValueNotifier<bool> noise = ValueNotifier(false);
  static final ValueNotifier<bool> parallax = ValueNotifier(false);

  // ── бут-экран ──
  static final ValueNotifier<bool> bootEnabled = ValueNotifier(true);
  static final ValueNotifier<double> bootDuration = ValueNotifier(3.5);
  static final ValueNotifier<String> bootCaption = ValueNotifier('');

  // ── фон ──
  static final ValueNotifier<bool> liveBg = ValueNotifier(true);
  static final ValueNotifier<Color?> bgColor = ValueNotifier(null);
  static final ValueNotifier<double> auroraSpeed = ValueNotifier(1.0);
  static final ValueNotifier<int> bgStyle = ValueNotifier(0);
  static final ValueNotifier<double> bgDensity = ValueNotifier(1.0);
  static final ValueNotifier<String?> bgImagePath = ValueNotifier(null);
  static final ValueNotifier<bool> compactSidebar = ValueNotifier(false);
  static final ValueNotifier<double> vignette = ValueNotifier(0.35);

  // ── графика ──
  static final ValueNotifier<int> fpsCap = ValueNotifier(24); // 12/24/30/60
  static final ValueNotifier<bool> ecoMode = ValueNotifier(false);
  // 💤 фокус окна — AFK-оптимизация фона
  static final ValueNotifier<bool> windowFocused = ValueNotifier(true);
    // 🎨 пользовательские пресеты
  static final List<Preset> _userPresets = [];
  static List<Preset> get userPresets => List.unmodifiable(_userPresets);
  // 🏁 разовое сообщение о финальном билде
   static final ValueNotifier<bool> finalNoticeShown = ValueNotifier(false);
  static final ValueNotifier<String?> appliedPresetId = ValueNotifier(null);
  static final ValueNotifier<bool> cardShadows = ValueNotifier(true);
    // ✨ визуальные фишки
  static final ValueNotifier<bool> rippleFx = ValueNotifier(true);
  static final ValueNotifier<bool> sweepFx = ValueNotifier(true);
  static final ValueNotifier<bool> cursorGlow = ValueNotifier(true);
  static final ValueNotifier<bool> pulseFx = ValueNotifier(true);
  static final ValueNotifier<bool> clockOn = ValueNotifier(true);
  static final ValueNotifier<bool> hotkeysOn = ValueNotifier(true);
  static final ValueNotifier<int> toastStyle = ValueNotifier(0); // 0 стекло, 1 неон, 2 минимал

  // ── звук ──
  static final ValueNotifier<bool> soundEnabled = ValueNotifier(true);
  static final ValueNotifier<double> soundVolume = ValueNotifier(0.3);
  static Map<String, String?> _sounds = {};
  static String? soundPath(String event) => _sounds[event];

  // ── стекло ──
  static final ValueNotifier<double> blurSigma = ValueNotifier(24.0);
  static final ValueNotifier<double> saturation = ValueNotifier(1.4);
  static final ValueNotifier<double> glassOpacity = ValueNotifier(0.42);
  static final ValueNotifier<double> edgeGlow = ValueNotifier(0.7);
  static final ValueNotifier<double> borderOpacity = ValueNotifier(0.22);
  static final ValueNotifier<double> specular = ValueNotifier(0.5);
  static final ValueNotifier<double> glassRadius = ValueNotifier(24.0);
  static final ValueNotifier<Color> glassTint =
      ValueNotifier(const Color(0xFFFFFFFF).withOpacity(0.05));
  static final ValueNotifier<bool> realBlur = ValueNotifier(false);

  static final Listenable general = Listenable.merge([
    isDark, language, uiScale, animationsEnabled, closeToTray, sidebarPos,
    accentColor, buttonColor, autoTheme, themeFrom, themeTo,
    alwaysOnTop, windowOpacity, fontMode,
    animSpeed, gradientAccent, accent2, noise, parallax, compactSidebar,
    bootEnabled, bootDuration, bootCaption, vignette, selectedConfig,
    rippleFx, pulseFx, clockOn, hotkeysOn, toastStyle, sweepFx, pulseFx, rippleFx,
  ]);
  static final Listenable glass = Listenable.merge([
    blurSigma, saturation, glassOpacity, edgeGlow, borderOpacity,
    specular, glassRadius, glassTint, realBlur,
    sweepFx, cursorGlow,
  ]);
  static final Listenable aurora = Listenable.merge([
    liveBg, bgColor, auroraSpeed, bgStyle, bgDensity, fpsCap, ecoMode,
    bgImagePath,
  ]);
  static final Listenable sound = Listenable.merge([soundEnabled, soundVolume]);
  static final Listenable all =
      Listenable.merge([general, glass, aurora, sound]);

  static File get _file =>
      File('${Platform.environment['APPDATA']}\\Z2Mini\\settings.json');

  static Timer? _saveDebounce;

  static Map<String, dynamic> _toJson() => {
        'isDark': isDark.value,
        'lang': language.value,
        'scale': uiScale.value,
        'anim': animationsEnabled.value,
        'tray': closeToTray.value,
        'sideP': sidebarPos.value,
        'accent': accentColor.value?.value,
        'autoTh': autoTheme.value,
        'thFrom': themeFrom.value,
        'thTo': themeTo.value,
        'aot': alwaysOnTop.value,
        'wOp': windowOpacity.value,
        'font': fontMode.value,
        'animSp': animSpeed.value,
        'grad': gradientAccent.value,
        'accent2': accent2.value?.value,
        'noise': noise.value,
        'parallax': parallax.value,
        'boot': bootEnabled.value,
        'bootDur': bootDuration.value,
        'bootCap': bootCaption.value,
        'liveBg': liveBg.value,
        'bg': bgColor.value?.value,
        'auroraSp': auroraSpeed.value,
        'bgStyle': bgStyle.value,
        'bgDens': bgDensity.value,
        'bgImg': bgImagePath.value,
        'cSide': compactSidebar.value,
        'vig': vignette.value,
        'fps': fpsCap.value,
        'eco': ecoMode.value,
        'shadows': cardShadows.value,
        'sound': soundEnabled.value,
        'vol': soundVolume.value,
        'sounds': _sounds,
        'blur': blurSigma.value,
        'sat': saturation.value,
        'op': glassOpacity.value,
        'glow': edgeGlow.value,
        'border': borderOpacity.value,
        'spec': specular.value,
        'radius': glassRadius.value,
        'tint': glassTint.value.value,
        'rblur': realBlur.value,
        'btn': buttonColor.value?.value,
        'zpath': zapretPath.value,
        'selcfg': selectedConfig.value,
        'presets': _userPresets.map((p) => p.toJson()).toList(),
        'finalNotice': finalNoticeShown.value,
        'appliedPreset': appliedPresetId.value,
        'rippleFx': rippleFx.value,
        'sweepFx': sweepFx.value,
        'pulseFx': pulseFx.value,
        'clockOn': clockOn.value,
        'hotkeys': hotkeysOn.value,
        'toastSt': toastStyle.value,
      };

  static void _writeDisk() {
    try {
      _file.parent.createSync(recursive: true);
      _file.writeAsStringSync(jsonEncode(_toJson()));
    } catch (_) {}
  }

  static void load() {
    try {
      if (_file.existsSync()) {
        final j = jsonDecode(_file.readAsStringSync());
        double d(String k, double def) => (j[k] ?? def).toDouble();
        bool b(String k, bool def) => j[k] ?? def;
        Color? c(String k) => j[k] != null ? Color(j[k] as int) : null;

        isDark.value = b('isDark', true);
        buttonColor.value = c('btn');
        language.value = j['lang'] ?? 'RU';
        uiScale.value = d('scale', 1.0);
        animationsEnabled.value = b('anim', true);
        closeToTray.value = b('tray', true);
        sidebarPos.value = (j['sideP'] ?? 0) as int;
        accentColor.value = c('accent');
        autoTheme.value = b('autoTh', false);
        themeFrom.value = (j['thFrom'] ?? 19 * 60) as int;
        themeTo.value = (j['thTo'] ?? 7 * 60) as int;
        alwaysOnTop.value = b('aot', false);
        windowOpacity.value = d('wOp', 1.0);
        fontMode.value = (j['font'] ?? 0) as int;
        animSpeed.value = d('animSp', 1.0);
        gradientAccent.value = b('grad', false);
        accent2.value = c('accent2');
        noise.value = b('noise', false);
        parallax.value = b('parallax', false);
        bootEnabled.value = b('boot', true);
        bootDuration.value = d('bootDur', 3.5);
        bootCaption.value = j['bootCap'] ?? '';
        liveBg.value = b('liveBg', true);
        bgColor.value = c('bg');
        auroraSpeed.value = d('auroraSp', 1.0);
        bgStyle.value = (j['bgStyle'] ?? 0) as int;
        bgDensity.value = d('bgDens', 1.0);
        bgImagePath.value = j['bgImg'];
        compactSidebar.value = b('cSide', false);
        vignette.value = d('vig', 0.35);
        fpsCap.value = (j['fps'] ?? 24) as int;
        ecoMode.value = b('eco', false);
        cardShadows.value = b('shadows', true);
        soundEnabled.value = b('sound', true);
        soundVolume.value = d('vol', 0.3);
        zapretPath.value = j['zpath'];
        selectedConfig.value = j['selcfg'];
        finalNoticeShown.value = b('finalNotice', false);
        appliedPresetId.value = j['appliedPreset'];
        rippleFx.value = b('rippleFx', true);
        sweepFx.value = b('sweepFx', true);
        pulseFx.value = b('pulseFx', true);
        clockOn.value = b('clockOn', true);
        hotkeysOn.value = b('hotkeys', true);
        toastStyle.value = (j['toastSt'] ?? 0) as int;
        final sm = j['sounds'];
        if (sm is Map) {
          _sounds = sm.map((k, v) => MapEntry(k as String, v as String?));
        }
        blurSigma.value = d('blur', 24.0);
        saturation.value = d('sat', 1.4);
        glassOpacity.value = d('op', 0.42);
        edgeGlow.value = d('glow', 0.7);
        borderOpacity.value = d('border', 0.22);
        specular.value = d('spec', 0.5);
        glassRadius.value = d('radius', 24.0);
        if (j['tint'] != null) glassTint.value = Color(j['tint'] as int);
        realBlur.value = b('rblur', false);
        _userPresets.clear();
        final pArr = j['presets'];
        if (pArr is List) {
          for (final p in pArr) {
            if (p is Map) {
              try {
                _userPresets.add(Preset.fromJson(p.cast<String, dynamic>()));
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {}
    UiSettingsLang.ru = language.value == 'RU';
    UiScale.value = uiScale.value;
  }

  static void save() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 300), _writeDisk);
  }

  static void saveImmediate() {
    _saveDebounce?.cancel();
    _writeDisk();
  }

  static void setSoundPath(String event, String? path) {
    _sounds[event] = path;
    save();
  }

  static void resetGlass() {
    blurSigma.value = 24.0;
    saturation.value = 1.4;
    glassOpacity.value = 0.42;
    edgeGlow.value = 0.7;
    borderOpacity.value = 0.22;
    specular.value = 0.5;
    glassRadius.value = 24.0;
    glassTint.value = const Color(0xFF60A5FA).withOpacity(0.15);
    realBlur.value = false;
    save();
  }

  static void resetAll() {
    isDark.value = true;
    language.value = 'RU';
    uiScale.value = 1.0;
    animationsEnabled.value = true;
    closeToTray.value = true;
    sidebarPos.value = 0;
    accentColor.value = null;
    autoTheme.value = false;
    themeFrom.value = 19 * 60;
    themeTo.value = 7 * 60;
    alwaysOnTop.value = false;
    windowOpacity.value = 1.0;
    fontMode.value = 0;
    animSpeed.value = 1.0;
    gradientAccent.value = false;
    accent2.value = null;
    noise.value = false;
    parallax.value = false;
    bootEnabled.value = true;
    bootDuration.value = 3.5;
    bootCaption.value = '';
    soundEnabled.value = true;
    soundVolume.value = 0.3;
    _sounds = {};
    liveBg.value = true;
    bgColor.value = null;
    auroraSpeed.value = 1.0;
    bgStyle.value = 0;
    bgDensity.value = 1.0;
    compactSidebar.value = false;
    vignette.value = 0.35;
    fpsCap.value = 24;
    ecoMode.value = false;
    cardShadows.value = true;
    buttonColor.value = null;
    resetGlass();
    UiSettingsLang.ru = true;
    UiScale.value = 1.0;
    saveImmediate();
  }

  static void setLang(String v) {
    language.value = v;
    UiSettingsLang.ru = v == 'RU';
    save();
  }

    // 📸 слепок текущих настроек (всё, что попадает в JSON)
  static Map<String, dynamic> _snapshot() => _toJson()..remove('presets');

  /// Применить пресет
  static void applyPreset(Preset p) {
    final d = p.data;
    if (d.containsKey('isDark')) isDark.value = d['isDark'] as bool;
    if (d['accent'] != null) accentColor.value = Color(d['accent'] as int);
    else accentColor.value = null;
    if (d['accent2'] != null) accent2.value = Color(d['accent2'] as int);
    else accent2.value = null;
    if (d.containsKey('grad')) gradientAccent.value = d['grad'] as bool;
    if (d['btn'] != null) buttonColor.value = Color(d['btn'] as int);
    else buttonColor.value = null;
    if (d.containsKey('radius')) glassRadius.value = (d['radius'] as num).toDouble();
    if (d.containsKey('blur')) blurSigma.value = (d['blur'] as num).toDouble();
    if (d.containsKey('sat')) saturation.value = (d['sat'] as num).toDouble();
    if (d.containsKey('op')) glassOpacity.value = (d['op'] as num).toDouble();
    if (d.containsKey('glow')) edgeGlow.value = (d['glow'] as num).toDouble();
    if (d.containsKey('border')) borderOpacity.value = (d['border'] as num).toDouble();
    if (d.containsKey('spec')) specular.value = (d['spec'] as num).toDouble();
    if (d['tint'] != null) glassTint.value = Color(d['tint'] as int);
    if (d.containsKey('font')) fontMode.value = d['font'] as int;
    if (d.containsKey('bgStyle')) bgStyle.value = d['bgStyle'] as int;
    if (d['bg'] != null) bgColor.value = Color(d['bg'] as int);
    else bgColor.value = null;
    if (d.containsKey('auroraSp')) auroraSpeed.value = (d['auroraSp'] as num).toDouble();
    if (d.containsKey('bgDens')) bgDensity.value = (d['bgDens'] as num).toDouble();
    if (d.containsKey('vig')) vignette.value = (d['vig'] as num).toDouble();
    if (d.containsKey('animSp')) animSpeed.value = (d['animSp'] as num).toDouble();
    if (d.containsKey('fps')) fpsCap.value = d['fps'] as int;
    if (d.containsKey('eco')) ecoMode.value = d['eco'] as bool;
    if (d.containsKey('sideP')) sidebarPos.value = d['sideP'] as int;
    if (d.containsKey('cSide')) compactSidebar.value = d['cSide'] as bool;
    if (d.containsKey('liveBg')) liveBg.value = d['liveBg'] as bool;
    appliedPresetId.value = p.id;
    save();
  }

  /// Создать пользовательский пресет из текущих настроек
  static Preset createUserPreset(String name, String description) {
    final p = Preset(
      id: 'user.${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      builtin: false,
      data: _snapshot(),
    );
    _userPresets.add(p);
    save();
    return p;
  }

  static Map<String, dynamic> presetSnapshot() => _snapshot();

  static bool updatePreset(String id, Map<String, dynamic> data) {
    final i = _userPresets.indexWhere((p) => p.id == id);
    if (i < 0) return false;
    final old = _userPresets[i];
    _userPresets[i] = Preset(
        id: old.id,
        name: old.name,
        description: old.description,
        builtin: false,
        data: data);
    save();
    return true;
  }

  /// Импортировать из строки (share-код). null если невалидно.
  static Preset? importFromString(String s) {
    final p = Preset.import(s);
    if (p == null) return null;
    _userPresets.add(p);
    save();
    return p;
  }

  /// Удалить пользовательский пресет
  static bool removePreset(String id) {
    final idx = _userPresets.indexWhere((p) => p.id == id);
    if (idx < 0) return false;
    _userPresets.removeAt(idx);
    save();
    return true;
  }

  /// Экспорт текущего состояния в шар-строку
  static String exportCurrent(String name, String description) {
    final p = Preset(
      id: 'share.${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      data: _snapshot(),
    );
    return p.export();
  }
}