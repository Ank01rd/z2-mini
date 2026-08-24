import 'package:flutter/material.dart';

class UiScale {
  static double _v = 1.0;
  static double get value => _v;
  static set value(double v) => _v = v;
}

double sc(double v) => v * UiScale.value;

extension EdgeInsetsScale on EdgeInsets {
  EdgeInsets scaleBy(double s) =>
      EdgeInsets.fromLTRB(left * s, top * s, right * s, bottom * s);
}