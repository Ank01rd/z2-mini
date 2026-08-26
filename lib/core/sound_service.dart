import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'ui_settings.dart';

/// 🔊 Саунд-дизайн Z2 Mini: короткие звуки на ключевые события.
/// Рецепт воспроизведения взят из Z2 pro — там хруста НЕТ:
///   1) setVolume ДО старта
///   2) stop() — жёсткий сброс плеера
///   3) play()
/// Никаких смен громкости во время воспроизведения —
/// именно они «хрустели» в мини (зиппер-шум на Windows).
class SoundService {
  static final AudioPlayer _p = AudioPlayer();

  /// событие → стандартный ассет
  static const Map<String, String> _defaults = {
    'click': 'click.wav',
    'toggle': 'click.wav',
    'on': 'turn_on.wav',
    'off': 'turn_off.wav',
    'start': 'turn_on.wav',
    'stop': 'turn_off.wav',
    'restart': 'restart.wav',
    'notify': 'notification.wav',
    'update': 'notification.wav',
    'complete': 'complete.wav',
    'error': 'error.wav',
  };

  static const Map<String, String> labels = {
    'start': 'Запуск',
    'stop': 'Остановка',
    'restart': 'Перезапуск',
    'click': 'Клик',
    'toggle': 'Переключатель',
    'on': 'Включение',
    'off': 'Выключение',
    'notify': 'Уведомление',
    'update': 'Обновление',
    'complete': 'Готово',
    'error': 'Ошибка',
  };

  static Future<void> play(String event) async {
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

      // 🎯 как в Z2 pro: громкость → сброс → старт.
      // Громкость берём из слайдера настроек (вместо профовских 0.1).
      await _p.setVolume(UiSettings.soundVolume.value);
      if (_p.state == PlayerState.playing) {
        await _p.stop();
      }
      await _p.play(src);
    } catch (e) {
      debugPrint('Sound: $e');
    }
  }

  /// 🕳 стаб для совместимости: если в main.dart остался вызов
  ///    SoundService.warmup() — он больше не нужен, рецепт и так чистый.
  static Future<void> warmup() async {}

  static Future<void> preview(String event) => play(event);
  static Future<void> click() => play('click');
  static Future<void> toggle() => play('toggle');
  static Future<void> start() => play('start');
  static Future<void> stop() => play('stop');
  static Future<void> restart() => play('restart');
  static Future<void> on() => play('on');
  static Future<void> off() => play('off');
  static Future<void> update() => play('update');
  static Future<void> complete() => play('complete');
  static Future<void> notify() => play('notify');
  static Future<void> error() => play('error');
}