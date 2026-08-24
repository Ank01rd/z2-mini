import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'ui_scale.dart';

class UiSettings {
  // ── интерфейс ──
  static final ValueNotifier<bool> isDark = ValueNotifier(true);
  static final ValueNotifier<String> language = ValueNotifier('RU');
  static final ValueNotifier<double> uiScale = ValueNotifier(1.0);
  static final ValueNotifier<bool> animationsEnabled = ValueNotifier(true);
  static final ValueNotifier<bool> closeToTray = ValueNotifier(true);
  static final ValueNotifier<bool> sidebarRight = ValueNotifier(false);
  static final ValueNotifier<Color?> accentColor = ValueNotifier(null);
  static final ValueNotifier<Color?> buttonColor = ValueNotifier(null);
  static final ValueNotifier<bool> autoTheme = ValueNotifier(false);
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
  static final ValueNotifier<double> vignette = ValueNotifier(0.35);

  // ── графика ──
  static final ValueNotifier<int> fpsCap = ValueNotifier(24); // 12/24/30/60
  static final ValueNotifier<bool> ecoMode = ValueNotifier(false);
  static final ValueNotifier<bool> cardShadows = ValueNotifier(true);

  // ── звук ──
  static final ValueNotifier<bool> soundEnabled = ValueNotifier(true);
  static final ValueNotifier<double> soundVolume = ValueNotifier(0.3);
  static Map<String, String?> _sounds = {};
  static String? soundPath(String event) => _sounds[event];

  // ── стекло (дефолт = iOS 26) ──
  static final ValueNotifier<double> blurSigma = ValueNotifier(24.0);
  static final ValueNotifier<double> saturation = ValueNotifier(1.4);
  static final ValueNotifier<double> glassOpacity = ValueNotifier(0.42);
  static final ValueNotifier<double> edgeGlow = ValueNotifier(0.7);
  static final ValueNotifier<double> borderOpacity = ValueNotifier(0.22);
  static final ValueNotifier<double> specular = ValueNotifier(0.5);
  static final ValueNotifier<double> glassRadius = ValueNotifier(24.0);
  static final ValueNotifier<Color> glassTint =
      ValueNotifier(const Color(0xFFFFFFFF).withOpacity(0.05));
  // 🪶 настоящий BackdropFilter ВЫКЛЮЧЕН по умолчанию (как в Z2 Manager):
  // на гладкой авроре стекло неотличимо, а GPU не платит за блюр каждый кадр
  static final ValueNotifier<bool> realBlur = ValueNotifier(false);

  static final Listenable general = Listenable.merge([
    isDark, language, uiScale, animationsEnabled, closeToTray, sidebarRight,
    accentColor, buttonColor, autoTheme, alwaysOnTop, windowOpacity, fontMode,
    animSpeed, gradientAccent, accent2, noise, parallax,
    bootEnabled, bootDuration, bootCaption, vignette, selectedConfig,
    cardShadows, ecoMode,
  ]);
  static final Listenable glass = Listenable.merge([
    blurSigma, saturation, glassOpacity, edgeGlow, borderOpacity,
    specular, glassRadius, glassTint, realBlur,
  ]);
  static final Listenable aurora = Listenable.merge([
    liveBg, bgColor, auroraSpeed, bgStyle, fpsCap, ecoMode,
  ]);
  static final Listenable sound = Listenable.merge([soundEnabled, soundVolume]);
  static final Listenable all = Listenable.merge([general, glass, aurora, sound]);

  static File get _file =>
      File('${Platform.environment['APPDATA']}\\Z2Mini\\settings.json');

  // ⚡ Дебаунсер: при частых изменениях (слайдеры) — пишем на диск раз в 300мс
  static Timer? _saveDebounce;

  static Map<String, dynamic> _toJson() => {
    'isDark': isDark.value,
    'lang': language.value,
    'scale': uiScale.value,
    'anim': animationsEnabled.value,
    'tray': closeToTray.value,
    'sideR': sidebarRight.value,
    'accent': accentColor.value?.value,
    'autoTh': autoTheme.value,
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
        sidebarRight.value = b('sideR', false);
        accentColor.value = c('accent');
        autoTheme.value = b('autoTh', false);
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
        vignette.value = d('vig', 0.35);

        fpsCap.value = (j['fps'] ?? 24) as int;
        ecoMode.value = b('eco', false);
        cardShadows.value = b('shadows', true);

        soundEnabled.value = b('sound', true);
        soundVolume.value = d('vol', 0.3);
        zapretPath.value = j['zpath'];
        selectedConfig.value = j['selcfg'];
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
      }
    } catch (_) {}
    UiSettingsLang.ru = language.value == 'RU';
    UiScale.value = uiScale.value;
  }

  /// Отложенное сохранение (для слайдеров, частых изменений)
  static void save() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 300), _writeDisk);
  }

  /// Немедленное сохранение (для выхода из приложения)
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
    sidebarRight.value = false;
    accentColor.value = null;
    autoTheme.value = false;
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
}