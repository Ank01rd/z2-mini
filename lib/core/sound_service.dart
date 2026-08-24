import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'ui_settings.dart';

/// 🔊 Саунд-дизайн Z2 Mini: короткие звуки на ключевые события.
/// Мягкая атака МЕЛКИМИ шагами громкости — без резкости и без «хруста».
class SoundService {
  static final AudioPlayer _p = AudioPlayer();

  /// событие → стандартный ассет
  static const Map<String, String> _defaults = {
    'click': 'Ui.wav',
    'toggle': 'Ui2.wav',
    'start': 'CRM 10.wav',
    'stop': 'CRS 5.wav',
    'toast': 'Ui3.mp3',
    'notify': 'neverlose.wav',
    'error': 'Ui2.wav',
  };

  static const Map<String, String> labels = {
    'start': 'Запуск',
    'stop': 'Остановка',
    'click': 'Клик',
    'toggle': 'Переключатель',
    'toast': 'Тост',
    'notify': 'Уведомление',
    'error': 'Ошибка',
  };

  static Future<void> play(String event, {int fadeMs = 100}) async {
    if (!UiSettings.soundEnabled.value) return;
    try {
      final custom = UiSettings.soundPath(event);
      Source? src;
      if (custom != null) {
        src = DeviceFileSource(custom);
      } else if (_defaults.containsKey(event)) {
        src = AssetSource(_defaults[event]!);
      }
      if (src == null) return;

      // не трогаем плеер, если он простаивает — убирает щелчок
      if (_p.state == PlayerState.playing) await _p.stop();

      final target = UiSettings.soundVolume.value;
      if (fadeMs <= 0) {
        await _p.setVolume(target);
        await _p.play(src);
        return;
      }

      // плавная атака: старт с 10%, далее 10 мелких шагов по ~10%
      await _p.setVolume(target * 0.1);
      await _p.play(src);
      const steps = 10;
      for (var i = 1; i <= steps; i++) {
        await Future.delayed(Duration(milliseconds: fadeMs ~/ steps));
        await _p.setVolume(target * (0.1 + 0.9 * i / steps));
      }
    } catch (e) {
      debugPrint('Sound: $e');
    }
  }

  static Future<void> preview(String event) => play(event);
  static Future<void> click() => play('click', fadeMs: 30);
  static Future<void> toggle() => play('toggle', fadeMs: 50);
  static Future<void> start() => play('start');
  static Future<void> stop() => play('stop');
  static Future<void> notify() => play('notify', fadeMs: 160);
  static Future<void> error() => play('error');
}