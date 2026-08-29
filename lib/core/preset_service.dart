import 'dart:convert';

class Preset {
  final String id;
  final String name;
  final String description;
  final bool builtin;
  final Map<String, dynamic> data;

  Preset({
    required this.id,
    required this.name,
    this.description = '',
    this.builtin = false,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'desc': description,
        'builtin': builtin,
        'data': data,
      };

  factory Preset.fromJson(Map<String, dynamic> j) => Preset(
        id: j['id'] as String,
        name: j['name'] as String,
        description: (j['desc'] as String?) ?? '',
        builtin: (j['builtin'] as bool?) ?? false,
        data: (j['data'] as Map?)?.cast<String, dynamic>() ?? {},
      );

  String export() {
    final raw = jsonEncode(toJson());
    return 'z2m:v1:${base64Encode(utf8.encode(raw))}';
  }

  static Preset? import(String s) {
    try {
      final trimmed = s.trim();
      if (!trimmed.startsWith('z2m:v1:')) return null;
      final b64 = trimmed.substring(7);
      final raw = utf8.decode(base64Decode(b64));
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final p = Preset.fromJson(j);
      return Preset(
        id: 'user.${DateTime.now().millisecondsSinceEpoch}',
        name: p.name,
        description: p.description,
        builtin: false,
        data: p.data,
      );
    } catch (_) {
      return null;
    }
  }
}

class BuiltinPresets {
  static Preset get liquidGlass => Preset(
        id: 'builtin.glass',
        name: 'Liquid Glass',
        description:
            'Эталонный вайб: спокойные цвета, умеренный блюр, системный шрифт.',
        builtin: true,
        data: const {
          'isDark': true,
          'accent': null,
          'accent2': null,
          'grad': false,
          'btn': null,
          'radius': 24.0,
          'blur': 24.0,
          'sat': 1.4,
          'op': 0.42,
          'glow': 0.70,
          'border': 0.22,
          'spec': 0.50,
          'tint': null,
          'font': 0,
          'bgStyle': 0,
          'bg': null,
          'auroraSp': 1.0,
          'bgDens': 1.0,
          'vig': 0.35,
          'animSp': 1.0,
          'fps': 24,
          'eco': false,
          'sideP': 0,
          'cSide': false,
          'liveBg': true,
        },
      );

  static const String _devThemeCode =
      'z2m:v1:eyJpZCI6InVzZXIuMTc4Nzg1MjA0NTI4MyIsIm5hbWUiOiJEZXYgdGhlbWUiLCJkZXNjIjoiIiwiYnVpbHRpbiI6ZmFsc2UsImRhdGEiOnsiaXNEYXJrIjp0cnVlLCJsYW5nIjoiUlUiLCJzY2FsZSI6MS4wMDIwNDM1MzQzNTY5NzMsImFuaW0iOnRydWUsInRyYXkiOnRydWUsInNpZGVQIjowLCJhY2NlbnQiOjQyODEyMTY1NTgsImF1dG9UaCI6ZmFsc2UsInRoRnJvbSI6MTAzNiwidGhUbyI6MjEzLCJhb3QiOmZhbHNlLCJ3T3AiOjEuMCwiZm9udCI6MCwiYW5pbVNwIjoxLjAsImdyYWQiOmZhbHNlLCJhY2NlbnQyIjpudWxsLCJub2lzZSI6ZmFsc2UsInBhcmFsbGF4IjpmYWxzZSwiYm9vdCI6ZmFsc2UsImJvb3REdXIiOjIuMCwiYm9vdENhcCI6IiIsImxpdmVCZyI6dHJ1ZSwiYmciOjQyOTQ5NjcyOTUsImF1cm9yYVNwIjoyLjUxNDk4MTAzNDIyMTUzNiwiYmdTdHlsZSI6NCwiYmdEZW5zIjoxLjcyMDUxMzk2OTI0NDkxMTgsImNTaWRlIjp0cnVlLCJ2aWciOjAuMCwiZnBzIjozMCwiZWNvIjpmYWxzZSwic2hhZG93cyI6dHJ1ZSwic291bmQiOnRydWUsInZvbCI6MC4xNzY4ODMxMjk2MDA3MTQxLCJzb3VuZHMiOnsibm90aWZ5IjpudWxsLCJzdGFydCI6bnVsbCwic3RvcCI6bnVsbH0sImJsdXIiOjUuOTcyODc5NjMyOTc3MDM5LCJzYXQiOjEuMTA4MzI3ODY1MTc5MjE0LCJvcCI6MC4wMDUwNDQyOTA2MjA5NzQzOTksImdsb3ciOjAuMzQ5NDcxOTYwNTg2Mjk1MjYsImJvcmRlciI6MC4xNDk1ODI2NDc5NTgwMTIyNywic3BlYyI6MC4wOTM0ODgyMjg1Mzg3NzgxNywicmFkaXVzIjoyOS44NDM4ODU4NDI4ODI3NywidGludCI6NjM3NTM0MjA4LCJyYmx1ciI6ZmFsc2UsImJ0biI6NDI4Mjg2MTM4MywienBhdGgiOiJDOlxcemFwcmV0X3Byb2dyYW1tXFx6YXByZXQtZGlzY29yZC15b3V0dWJlLTEuMTAuMVxcemFwcmV0LWRpc2NvcmQteW91dHViZS0xLjEwLjIiLCJzZWxjZmciOiJnZW5lcmFsIChBTFQxMikuYmF0IiwiZmluYWxOb3RpY2UiOnRydWUsImFwcGxpZWRQcmVzZXQiOiJidWlsdGluLmRldiJ9fQ==';

  static Preset get devTheme {
    final p = Preset.import(_devThemeCode);
    return Preset(
      id: 'builtin.dev',
      name: 'Dev Theme',
      description: p?.description ?? 'Чёрно-белый акцент с приятными настройками',
      builtin: true,
      data: p?.data ?? {},
    );
  }

  static List<Preset> get all => [liquidGlass, devTheme];
}