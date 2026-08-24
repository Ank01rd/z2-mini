import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';  // ← ДОБАВЛЕНО (нужно для Icons)
import 'package:window_manager/window_manager.dart';
import '../core/notify_service.dart';

class ReleaseInfo {
  final String version;
  final String url;
  final int size;
  const ReleaseInfo({required this.version, required this.url, this.size = 0});
}

/// 🔄 Обновления через GitHub Releases
class UpdateService {
  /// ⚠️ ТВОЙ РЕПОЗИТОРИЙ: 'ник/имя-репы'
  static const String repo = 'Ank01rd/z2-mini';

  /// текущая версия — МЕНЯЙ при каждом релизе!
  static const String currentVersion = '1.0.0';

  static bool _busy = false;

  static String get _exeDir => File(Platform.resolvedExecutable).parent.path;

  static List<int> _parts(String v) => v
      .replaceAll(RegExp(r'[^0-9.]'), '')
      .split('.')
      .where((e) => e.isNotEmpty)
      .map((e) => int.tryParse(e) ?? 0)
      .toList();

  static bool isNewer(String remote, String current) {
    final a = _parts(remote), b = _parts(current);
    for (var i = 0; i < 3; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  /// смотрим последний релиз; null = обновы нет / ошибка
  static Future<ReleaseInfo?> check() async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(
          Uri.parse('https://api.github.com/repos/$repo/releases/latest'));
      req.headers.set('User-Agent', 'Z2-Mini');
      final resp = await req.close();
      if (resp.statusCode != 200) {
        client.close();
        return null;
      }
      final data = jsonDecode(await resp.transform(utf8.decoder).join());
      client.close();
      final tag = '${data['tag_name']}';
      if (!isNewer(tag, currentVersion)) return null;
      String? url;
      var size = 0;
      for (final a in (data['assets'] as List? ?? []).cast<Map<String, dynamic>>()) {
        final n = (a['name'] as String).toLowerCase();
        if (n.endsWith('.zip') && n.contains('windows')) {
          url = a['browser_download_url'] as String;
          size = a['size'] as int? ?? 0;
          break;
        }
      }
      if (url == null) return null;
      return ReleaseInfo(version: tag, url: url, size: size);
    } catch (_) {
      return null;
    }
  }

  /// качаем → распаковываем → bat-обновлятор → перезапуск
  static Future<void> startUpdate(ReleaseInfo r) async {
    if (_busy) return;
    _busy = true;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final dir = Directory('${Platform.environment['APPDATA']}\\Z2Mini\\update')
        ..createSync(recursive: true);
      final zipPath = '${dir.path}\\z2_mini_update.zip';

      NotifyService.push('Обновление ${r.version}… 0%',
          icon: Icons.system_update_rounded, sound: false, progress: 0);

      final dl = await client.getUrl(Uri.parse(r.url));
      dl.headers.set('User-Agent', 'Z2-Mini');
      final resp = await dl.close();
      final total = resp.contentLength;
      final sink = File(zipPath).openWrite();
      var received = 0, last = -1;
      await for (final ch in resp) {
        sink.add(ch);
        received += ch.length;
        if (total > 0) {
          final pct = received * 100 ~/ total;
          if (pct != last) {
            last = pct;
            NotifyService.push('Обновление ${r.version} · $pct%',
                icon: Icons.system_update_rounded,
                sound: false,
                progress: pct / 100);
          }
        } else {
          NotifyService.push('Обновление… ${received ~/ 1048576} МБ',
              icon: Icons.system_update_rounded, sound: false);
        }
      }
      await sink.close();
      client.close();

      NotifyService.push('Установка обновления…',
          icon: Icons.system_update_rounded, sound: false);
      await _install(zipPath, dir.path);
    } catch (e) {
      NotifyService.push('Ошибка обновления: $e',
          icon: Icons.error_outline_rounded);
    } finally {
      _busy = false;
      try { client.close(); } catch (_) {}
    }
  }

  static Future<void> _install(String zipPath, String workDir) async {
    final src = '$workDir\\new';
    final unz = await Process.run('powershell', [
      '-Command',
      'Expand-Archive -LiteralPath "$zipPath" -DestinationPath "$src" -Force'
    ]);
    if (unz.exitCode != 0) {
      NotifyService.push('Ошибка распаковки обновления',
          icon: Icons.error_outline_rounded);
      return;
    }
    // если в архиве была обёртка-папка — заходим в неё
    var root = Directory(src);
    final hasExe =
        root.listSync().any((e) => e is File && e.path.toLowerCase().endsWith('.exe'));
    if (!hasExe) {
      final inner = root.listSync().whereType<Directory>().toList();
      if (inner.length == 1) root = inner.first;
    }

    final bat = '$workDir\\update.bat';
    await File(bat).writeAsString('''
@echo off
chcp 65001 >nul
timeout /t 2 /nobreak >nul
taskkill /F /IM z2_mini.exe >nul 2>&1
timeout /t 1 /nobreak >nul
xcopy /E /Y "${root.path}\\*" "$_exeDir\\" >nul
start "" "$_exeDir\\z2_mini.exe"
rmdir /S /Q "$workDir"
''');
    // запускаем обновлятор отдельно и выходим
    await Process.run('cmd', ['/c', 'start /min "Z2Update" "$bat"']);
    await windowManager.destroy();
  }
}