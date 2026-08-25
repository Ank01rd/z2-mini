import 'dart:convert';
import 'dart:io';

class ZapretService {
  static final ZapretService instance = ZapretService._();
  ZapretService._();

  String _zapretDir = r'C:\zapret_programm';
  String get zapretDir => _zapretDir;
  set zapretDir(String p) => _zapretDir = p;

  // ── сохранённый путь к папке Zapret ────────────────────────────

  Future<String?> getSavedPath() async {
    final file =
        File('${Platform.environment['APPDATA']}\\Z2Mini\\zapret_path.json');
    if (!await file.exists()) return null;
    try {
      return (jsonDecode(await file.readAsString()))['path'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> savePath(String path) async {
    final file =
        File('${Platform.environment['APPDATA']}\\Z2Mini\\zapret_path.json');
    file.parent.createSync(recursive: true);
    await file.writeAsString(jsonEncode({'path': path}));
  }

  // ── конфиги: все .bat кроме service.bat, сортировка как в проводнике ──

  Future<List<String>> scanConfigs() async {
    final dir = Directory(_zapretDir);
    if (!await dir.exists()) return [];
    final configs = <String>[];
    for (final e in dir.listSync()) {
      if (e is File) {
        final n = e.path.replaceAll('\\', '/').split('/').last.toLowerCase();
        if (n.endsWith('.bat') && n != 'service.bat') {
          configs.add(e.path.replaceAll('\\', '/').split('/').last);
        }
      }
    }
    configs.sort(_naturalCompare); // ALT2 раньше ALT10
    return configs;
  }

  /// «Проводниковая» сортировка: числа сравниваются как числа
  static int _naturalCompare(String a, String b) {
    final re = RegExp(r'(\d+|\D+)');
    final pa = re.allMatches(a).map((m) => m.group(0)!).toList();
    final pb = re.allMatches(b).map((m) => m.group(0)!).toList();
    for (var i = 0; i < pa.length && i < pb.length; i++) {
      final xa = pa[i], xb = pb[i];
      final numA = RegExp(r'^\d+$').hasMatch(xa);
      final numB = RegExp(r'^\d+$').hasMatch(xb);
      final c = (numA && numB)
          ? int.parse(xa).compareTo(int.parse(xb))
          : xa.toLowerCase().compareTo(xb.toLowerCase());
      if (c != 0) return c;
    }
    return pa.length.compareTo(pb.length);
  }

  // ── статус / запуск / остановка ────────────────────────────────

  Future<bool> isRunning() async {
    try {
      final r = await Process.run(
          'tasklist', ['/FI', 'IMAGENAME eq winws.exe', '/NH'],
          runInShell: true);
      return r.stdout.toString().toLowerCase().contains('winws.exe');
    } catch (_) {
      return false;
    }
  }

  Future<String> start(String configName) async {
    final path = '$_zapretDir\\$configName';
    await Process.run('powershell', [
      '-Command',
      'Start-Process -FilePath "cmd.exe" '
          '-ArgumentList \'/c ""$path""\' '
          '-WorkingDirectory "$_zapretDir" -Verb RunAs'
    ]);
    return 'Запуск: $configName (UAC)';
  }

  Future<String> stop() async {
    await Process.run('powershell', [
      '-Command',
      'Start-Process -FilePath "taskkill" '
          '-ArgumentList "/F /IM winws.exe" -Verb RunAs -WindowStyle Hidden'
    ]);
    return 'Остановка: winws.exe завершён';
  }

  // ── применение фильтров (Game / IPSet) ────────────────────────

  Future<void> applySettings({
    required String folder,
    required String gameFilter,
    required String ipsetFilter,
  }) async {
    final gameFile = File('$folder\\utils\\game_filter.enabled');
    try {
      if (gameFilter == 'disabled') {
        if (await gameFile.exists()) await gameFile.delete();
      } else {
        await gameFile.parent.create(recursive: true);
        await gameFile.writeAsString(gameFilter);
      }
    } catch (_) {}
  }

  // ── автозапуск через schtasks ─────────────────────────────────

  Future<String> installService(String folder) async {
    final configs = await scanConfigs();
    if (configs.isEmpty) return 'Нет конфигов для автозапуска';
    final cfg = configs.contains('general.bat') ? 'general.bat' : configs.first;
    await Process.run('powershell', [
      '-Command',
      'Start-Process -FilePath "schtasks" '
          '-ArgumentList \'/Create /TN "Z2-AutoStart" '
          '/SC ONLOGON /RL HIGHEST /TR ""$folder\\$cfg"" /F\' '
          '-Verb RunAs -WindowStyle Hidden'
    ]);
    return 'Автозапуск установлен: $cfg';
  }

  Future<String> removeService(String folder) async {
    await Process.run('powershell', [
      '-Command',
      'Start-Process -FilePath "schtasks" '
          '-ArgumentList \'/Delete /TN "Z2-AutoStart" /F\' '
          '-Verb RunAs -WindowStyle Hidden'
    ]);
    return 'Автозапуск удалён';
  }

  // ── обновление IPSet ──────────────────────────────────────────

  Future<String> updateIpset(String folder) async {
    try {
      await Directory('$folder\\lists').create(recursive: true);
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(Uri.parse(
          'https://raw.githubusercontent.com/Flowseal/zapret-discord-youtube/refs/heads/main/.service/ipset-service.txt'));
      req.headers.set('User-Agent', 'Z2-Mini');
      final resp = await req.close();
      if (resp.statusCode == 200) {
        final sink = File('$folder\\lists\\ipset-all.txt').openWrite();
        await resp.pipe(sink);
        await sink.close();
        client.close();
        return 'IPSet: список обновлён';
      }
      client.close();
      return 'IPSet: ошибка HTTP ${resp.statusCode}';
    } catch (e) {
      return 'IPSet: $e';
    }
  }

  // ── проверка обновлений приложения (Z2 Manager / Mini) ────────

  Future<String> checkAppUpdate() async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(Uri.parse(
          'https://api.github.com/repos/Ank01rd/ZapretManager/releases/latest'));
      req.headers.set('User-Agent', 'Z2-Mini');
      final resp = await req.close();
      if (resp.statusCode != 200) {
        client.close();
        return 'Ошибка HTTP: ${resp.statusCode}';
      }
      final data = jsonDecode(await resp.transform(utf8.decoder).join());
      client.close();
      return 'Последняя версия Z2: ${data['tag_name']}';
    } catch (e) {
      return 'Ошибка: $e';
    }
  }

  // ── проверка обновлений самого Zapret (Flowseal) ──────────────

  Future<String> checkZapretUpdate() async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(Uri.parse(
          'https://api.github.com/repos/Flowseal/zapret-discord-youtube/releases/latest'));
      req.headers.set('User-Agent', 'Z2-Mini');
      final resp = await req.close();
      if (resp.statusCode != 200) {
        client.close();
        return 'Ошибка HTTP: ${resp.statusCode}';
      }
      final data = jsonDecode(await resp.transform(utf8.decoder).join());
      client.close();
      return 'Flowseal: ${data['tag_name']}';
    } catch (e) {
      return 'Ошибка: $e';
    }
  }

  // ── скачивание и установка Zapret ─────────────────────────────

  Future<String> downloadZapret(String folder,
      {void Function(double? p, String stage)? onProgress}) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      onProgress?.call(null, 'Поиск релиза…');
      final req = await client.getUrl(Uri.parse(
          'https://api.github.com/repos/Flowseal/zapret-discord-youtube/releases/latest'));
      req.headers.set('User-Agent', 'Z2-Mini');
      final resp = await req.close();
      if (resp.statusCode != 200) return 'Ошибка HTTP: ${resp.statusCode}';
      final data = jsonDecode(await resp.transform(utf8.decoder).join());
      final assets = (data['assets'] as List).cast<Map<String, dynamic>>();
      String? url;
      for (final a in assets) {
        if ((a['name'] as String).toLowerCase().endsWith('.zip')) {
          url = a['browser_download_url'] as String;
          break;
        }
      }
      if (url == null) return 'В релизе нет .zip';

      final version = '${data['tag_name']}';
      await Directory(folder).create(recursive: true);
      final zipPath = '$folder\\zapret_download.zip';

      final dl = await client.getUrl(Uri.parse(url));
      dl.headers.set('User-Agent', 'Z2-Mini');
      final dlResp = await dl.close();
      final total = dlResp.contentLength;
      final sink = File(zipPath).openWrite();
      var received = 0;
      var lastPct = -1;

      await for (final chunk in dlResp) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          final pct = received * 100 ~/ total;
          if (pct != lastPct) {
            lastPct = pct;
            onProgress?.call(pct / 100, 'Скачивание $version · $pct%');
            await Future.delayed(const Duration(milliseconds: 50));
          }
        } else {
          onProgress?.call(
              null, 'Скачивание $version… ${received ~/ 1048576} МБ');
        }
      }
      await sink.close();
      onProgress?.call(null, 'Установка…');

      final unz = await Process.run('powershell', [
        '-Command',
        'Expand-Archive -LiteralPath "$zipPath" -DestinationPath "$folder" -Force'
      ]);
      try {
        await File(zipPath).delete();
      } catch (_) {}

      if (unz.exitCode != 0) return 'Ошибка распаковки';

      // 📦 поднимаем вложенную папку релиза прямо в $folder
      await _flatten(folder);

      try {
        await File('$folder\\version.txt').writeAsString(version);
      } catch (_) {}

      return 'Zapret $version скачан и установлен';
    } catch (e) {
      return 'Ошибка скачивания: $e';
    } finally {
      client.close();
    }
  }

  /// 📦 Если после распаковки появилась вложенная папка релиза
  ///    (zapret-discord-youtube-x.y.z) — сливаем её содержимое с корнем
  ///    и удаляем. Два прохода — на случай двойной вложенности.
  Future<void> _flatten(String dir) async {
    for (var pass = 0; pass < 2; pass++) {
      final root = Directory(dir);
      if (!await root.exists()) return;

      final nested = root
          .listSync()
          .whereType<Directory>()
          .where((d) => d.path
              .replaceAll('\\', '/')
              .split('/')
              .last
              .toLowerCase()
              .startsWith('zapret-discord-youtube'))
          .toList();

      if (nested.isEmpty) return;

      for (final d in nested) {
        await _moveInto(d, root);
        try {
          await d.delete(recursive: true);
        } catch (_) {}
      }
    }
  }

  /// Рекурсивно переносит содержимое src в dst, сливая существующие
  /// папки и заменяя файлы.
  Future<void> _moveInto(Directory src, Directory dst) async {
    for (final e in src.listSync()) {
      final name = e.path.replaceAll('\\', '/').split('/').last;
      final dest = '${dst.path}\\$name';
      try {
        if (e is Directory) {
          if (await Directory(dest).exists()) {
            await _moveInto(e, Directory(dest));
          } else {
            await e.rename(dest);
          }
        } else {
          if (await File(dest).exists()) await File(dest).delete();
          await e.rename(dest);
        }
      } catch (_) {}
    }
  }
}