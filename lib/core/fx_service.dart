import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FxRipple {
  final int id;
  final Offset pos;
  final int startMs;
  FxRipple(this.id, this.pos, this.startMs);
}

/// 💧💫✨ Ripple, пульс (из кнопки!) и свечение курсора
class FxService {
  static final ValueNotifier<List<FxRipple>> ripples = ValueNotifier([]);
  static final ValueNotifier<int> pulseVer = ValueNotifier(0);
  static final ValueNotifier<Offset?> cursor = ValueNotifier(null);
  static Offset? pulseOrigin;
  static int _id = 0;

  static void ripple(Offset p) {
    ripples.value = [
      ...ripples.value.take(14),
      FxRipple(_id++, p, DateTime.now().millisecondsSinceEpoch),
    ];
  }

  /// Пульс из точки (глобальные координаты кнопки) или из центра, если null
  static void pulse([Offset? origin]) {
    pulseOrigin = origin;
    pulseVer.value++;
  }

  static void dropOld(int nowMs) {
    if (ripples.value.any((r) => nowMs - r.startMs > 900)) {
      ripples.value =
          ripples.value.where((r) => nowMs - r.startMs <= 900).toList();
    }
  }
}