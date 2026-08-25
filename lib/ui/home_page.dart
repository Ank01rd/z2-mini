import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/ui_scale.dart';
import '../core/ui_settings.dart';
import '../services/zapret_service.dart';
import '../services/update_service.dart';
import 'liquid_glass_container.dart';
import 'style/widgets.dart';
import '../core/sound_service.dart';
import '../core/notify_service.dart';

class HomePage extends StatefulWidget {
  final AppTheme theme;
  const HomePage({super.key, required this.theme});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _zapret = ZapretService.instance;
  List<String> _configs = [];
  bool _isRunning = false, _cfgOpen = false, _busy = false;
  bool _gameOpen = false, _ipsetOpen = false;
  String _gameFilter = 'all', _ipsetFilter = 'loaded';
  String _cfgFilter = 'all';
  AppTheme get t => widget.theme;

  @override
  void initState() {
    super.initState();
    UiSettings.zapretPath.addListener(_onPathChanged);
    _init();
  }

  @override
  void dispose() {
    UiSettings.zapretPath.removeListener(_onPathChanged);
    super.dispose();
  }

  void _onPathChanged() {
    final p = UiSettings.zapretPath.value;
    if (p != null && p.isNotEmpty) _zapret.zapretDir = p;
    _refresh();
  }

  Future<void> _init() async {
    final saved = await _zapret.getSavedPath() ?? UiSettings.zapretPath.value;
    if (saved != null) _zapret.zapretDir = saved;
    await _refresh();
  }

  Future<void> _refresh() async {
    final configs = await _zapret.scanConfigs();
    final running = await _zapret.isRunning();
    if (!mounted) return;
    setState(() {
      _configs = configs;
      _isRunning = running;
      if (_configs.isNotEmpty && UiSettings.selectedConfig.value == null) {
        UiSettings.selectedConfig.value = _configs.first;
        UiSettings.save();
      }
      if (_configs.isEmpty) UiSettings.selectedConfig.value = null;
    });
  }

  Future<void> _start() async {
    final sel = UiSettings.selectedConfig.value;
    if (sel == null) {
      ToastService.show(tr('Не выбран конфиг', 'No config'), Icons.error_outline_rounded);
      return;
    }
    await _zapret.applySettings(
      folder: _zapret.zapretDir,
      gameFilter: _gameFilter,
      ipsetFilter: _ipsetFilter,
    );
    await _zapret.start(sel);
    // 🔊 сначала звук запуска, потом ТИХИЙ тост —
    //    иначе notify от тоста обрывает звук старта
    SoundService.start();
    NotifyService.push(tr('Zapret активен', 'Zapret active'),
        icon: Icons.rocket_launch_rounded, sound: false);
    // ⚡ Оптимизация: ретрай статус вместо слепой задержки
    for (var i = 0; i < 5; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      final running = await _zapret.isRunning();
      if (running) break;
    }
    await _refresh();
  }

  Future<void> _guard(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
    } catch (_) {}
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _stop() async {
    await _zapret.stop();
    SoundService.stop();
    NotifyService.push(tr('Остановлен', 'Stopped'),
        icon: Icons.stop_circle_rounded, sound: false);
    for (var i = 0; i < 5; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      final running = await _zapret.isRunning();
      if (!running) break;
    }
    await _refresh();
  }

  Future<void> _restart() async {
    await _stop();
    await Future.delayed(const Duration(milliseconds: 500));
    await _start();
  }

  String _gameSummary() {
    switch (_gameFilter) {
      case 'disabled': return tr('Отключено', 'Disabled');
      case 'tcp': return tr('Только TCP', 'TCP only');
      case 'udp': return tr('Только UDP', 'UDP only');
      default: return tr('TCP и UDP', 'TCP and UDP');
    }
  }

  String _ipsetSummary() {
    switch (_ipsetFilter) {
      case 'disabled': return tr('Отключено', 'Disabled');
      case 'any': return tr('Любой', 'Any');
      default: return tr('Загруженный', 'Loaded');
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) {},
    child: LayoutBuilder(
      builder: (ctx, c) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: Padding(
            padding: EdgeInsets.fromLTRB(sc(16), sc(44), sc(16), sc(16)),
            child: Center(
              child: IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(flex: 1, child: AnimatedReveal(i: 0, child: _configCard())),
                  SizedBox(width: sc(12)),
                  Expanded(flex: 1, child: AnimatedReveal(i: 1, child: _filtersCard())),
                  SizedBox(width: sc(12)),
                  Expanded(flex: 1, child: AnimatedReveal(i: 2, child: _actionsCard())),
                ]),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _head(String s, IconData ic) => Row(children: [
    Icon(ic, color: t.accent, size: sc(16)),
    SizedBox(width: sc(8)),
    Text(s, style: TextStyle(fontSize: sc(14), fontWeight: FontWeight.w700, color: t.text)),
    const Spacer(),
  ]);

    Widget _configCard() => LiquidGlassContainer(
        theme: t,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: sc(20),
                child: _head(tr('Конфигурация', 'Configuration'), Icons.tune_rounded)),
            SizedBox(height: sc(4)),
            _configHeader(),
            // 📋 список растёт вниз
            ClipRect(
              child: AnimatedAlign(
                alignment: Alignment.topCenter,
                heightFactor: _cfgOpen ? 1 : 0,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: _configListBody(),
              ),
            ),
            // 🔘 кнопки прячутся ВНИЗ: уезжают вниз и обрезаются,
            //    ширина не анимируется — никакого «уезда вбок»
            ClipRect(
              child: AnimatedAlign(
                alignment: Alignment.topCenter,
                heightFactor: _cfgOpen ? 0 : 1,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInCubic,
                child: AnimatedSlide(
                  offset: _cfgOpen ? const Offset(0, 1) : Offset.zero,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInCubic,
                  child: Column(children: [
                    SizedBox(height: sc(10)),
                    _btn(tr('Запустить', 'Start'), Icons.rocket_launch_rounded,
                        _isRunning ? null : () => _guard(_start),
                        base: t.buttonColor, fg: t.buttonTextColor),
                    SizedBox(height: sc(6)),
                    _btn(tr('Остановить', 'Stop'), Icons.stop_circle_rounded,
                        _isRunning ? () => _guard(_stop) : null,
                        fg: const Color(0xFFEF4444)),
                    SizedBox(height: sc(6)),
                    _btn(tr('Перезапустить', 'Restart'), Icons.refresh_rounded,
                        _isRunning ? () => _guard(_restart) : null),
                    SizedBox(height: sc(6)),
                    _btn(tr('В автозапуск', 'Add to Startup'), Icons.start_rounded,
                        () async {
                      final r = await _zapret.installService(_zapret.zapretDir);
                      ToastService.show(r, Icons.start_rounded);
                    }),
                    SizedBox(height: sc(6)),
                    _btn(tr('Из автозапуска', 'Remove Startup'),
                        Icons.do_not_disturb_rounded, () async {
                      final r = await _zapret.removeService(_zapret.zapretDir);
                      ToastService.show(r, Icons.do_not_disturb_rounded);
                    }),
                  ]),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _configHeader() => SizedBox(
        height: sc(34),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _cfgOpen = !_cfgOpen),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: sc(4), vertical: sc(4)),
              child: Row(children: [
                Icon(Icons.article_rounded, size: sc(16), color: t.accent),
                SizedBox(width: sc(8)),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Configs',
                      style: TextStyle(
                          fontSize: sc(13),
                          fontWeight: FontWeight.w700,
                          color: t.text)),
                  AnimatedSwitchedText(
                    open: _cfgOpen,
                    summary: UiSettings.selectedConfig.value ??
                        tr('Выберите конфиг', 'Select config'),
                    theme: t,
                  ),
                ])),
                AnimatedRotation(
                  turns: _cfgOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      size: sc(18), color: t.text.withOpacity(0.6)),
                ),
              ]),
            ),
          ),
        ),
      );

  Widget _configListBody() => Padding(
        padding: EdgeInsets.only(bottom: sc(6)),
        child: Column(children: [
          SizedBox(
            height: sc(24),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: [
                for (final c in _cfgCats) ...[
                  _catChip(c[0], c[1]),
                  SizedBox(width: sc(6)),
                ],
              ],
            ),
          ),
          SizedBox(height: sc(6)),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: sc(190)),
            child: SingleChildScrollView(
              child: Column(children: [
                if (_filteredConfigs.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: sc(8)),
                    child: Text(tr('Конфиги не найдены', 'No configs found'),
                        style: TextStyle(
                            fontSize: sc(11),
                            color: t.text.withOpacity(0.5))),
                  ),
                for (final cfg in _filteredConfigs)
                  FilterRadio(
                    label: cfg,
                    selected: cfg == UiSettings.selectedConfig.value,
                    theme: t,
                    onTap: () {
                      UiSettings.selectedConfig.value = cfg;
                      UiSettings.save();
                      setState(() {});
                    },
                  ),
              ]),
            ),
          ),
        ]),
      );

   static const List<List<String>> _cfgCats = [
    ['all', 'Все'],
    ['alt', 'ALT'],
    ['fake', 'Fake TLS'],
    ['simple', 'Simple'],
    ['exp', 'EXP'],
    ['base', 'Base'],
  ];

  String _cfgCat(String n) {
    final u = n.toUpperCase();
    if (u.contains('FAKE TLS')) return 'fake';
    if (u.contains('SIMPLE FAKE')) return 'simple';
    if (u.contains('(EXP)')) return 'exp';
    if (u.contains('(ALT')) return 'alt';
    return 'base';
  }

  List<String> get _filteredConfigs => _cfgFilter == 'all'
      ? _configs
      : _configs.where((c) => _cfgCat(c) == _cfgFilter).toList();


  Widget _catChip(String id, String label) {
    final active = _cfgFilter == id;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _cfgFilter = id),
      child: AnimatedContainer(
        duration: t.animDur,
        curve: t.animCurve,
        padding: EdgeInsets.symmetric(horizontal: sc(10), vertical: sc(5)),
        decoration: BoxDecoration(
          color: active ? t.accent.withOpacity(0.8) : t.card.withOpacity(0.5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: active
                  ? t.accent
                  : Colors.white.withOpacity(t.isDark ? 0.10 : 0.5)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: sc(10),
                fontWeight: FontWeight.w700,
                color: active ? t.buttonTextColor : t.text.withOpacity(0.7))),
      ),
    );
  }

  Widget _btn(String label, IconData icon, VoidCallback? onPressed, {Color? base, Color? fg}) {
    final b = base ?? t.surface;
    final f = fg ?? t.text;
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: Btn25D(
        base: b,
        radius: 999,
        onTap: onPressed,
        padding: EdgeInsets.symmetric(vertical: sc(9)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: sc(15), color: f),
          SizedBox(width: sc(8)),
          Flexible(child: Text(label,
            style: TextStyle(fontSize: sc(12), color: f, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  Widget _filtersCard() => LiquidGlassContainer(theme: t, child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _head(tr('Фильтры', 'Filters'), Icons.filter_alt_rounded),
      SizedBox(height: sc(4)),
      _filterSection(
        title: 'Game Filter',
        icon: Icons.sports_esports_rounded,
        summary: _gameSummary(),
        open: _gameOpen,
        onToggle: () => setState(() => _gameOpen = !_gameOpen),
        children: [
          FilterRadio(label: tr('Отключено', 'Disabled'), selected: _gameFilter == 'disabled', theme: t,
            onTap: () => setState(() => _gameFilter = 'disabled')),
          FilterRadio(label: tr('TCP и UDP', 'TCP and UDP'), selected: _gameFilter == 'all', theme: t,
            onTap: () => setState(() => _gameFilter = 'all')),
          FilterRadio(label: tr('Только TCP', 'TCP only'), selected: _gameFilter == 'tcp', theme: t,
            onTap: () => setState(() => _gameFilter = 'tcp')),
          FilterRadio(label: tr('Только UDP', 'UDP only'), selected: _gameFilter == 'udp', theme: t,
            onTap: () => setState(() => _gameFilter = 'udp')),
        ],
      ),
      Padding(
        padding: EdgeInsets.symmetric(vertical: sc(6)),
        child: Container(height: 1, color: Colors.white.withOpacity(t.isDark ? 0.08 : 0.3)),
      ),
      _filterSection(
        title: 'IPSet Filter',
        icon: Icons.language_rounded,
        summary: _ipsetSummary(),
        open: _ipsetOpen,
        onToggle: () => setState(() => _ipsetOpen = !_ipsetOpen),
        children: [
          FilterRadio(label: tr('Отключено', 'Disabled'), selected: _ipsetFilter == 'disabled', theme: t,
            onTap: () => setState(() => _ipsetFilter = 'disabled')),
          FilterRadio(label: tr('Любой', 'Any'), selected: _ipsetFilter == 'any', theme: t,
            onTap: () => setState(() => _ipsetFilter = 'any')),
          FilterRadio(label: tr('Загруженный', 'Loaded'), selected: _ipsetFilter == 'loaded', theme: t,
            onTap: () => setState(() => _ipsetFilter = 'loaded')),
        ],
      ),
    ],
  ));

  Widget _filterSection({
    required String title,
    required IconData icon,
    required String summary,
    required bool open,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Column(children: [
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onToggle,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: sc(4), vertical: sc(6)),
            child: Row(children: [
              Icon(icon, size: sc(16), color: t.accent),
              SizedBox(width: sc(8)),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontSize: sc(13), fontWeight: FontWeight.w700, color: t.text)),
                AnimatedSwitchedText(open: open, summary: summary, theme: t),
              ])),
              AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: Icon(Icons.keyboard_arrow_down_rounded, size: sc(18),
                  color: t.text.withOpacity(0.6)),
              ),
            ]),
          ),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: open
            ? Padding(padding: EdgeInsets.only(bottom: sc(4)), child: Column(children: children))
            : const SizedBox.shrink(),
      ),
    ]);
  }

  Widget _actionsCard() => LiquidGlassContainer(theme: t, child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _head(tr('Действия', 'Actions'), Icons.build_rounded),
      SizedBox(height: sc(10)),
      _act(tr('Диагностика', 'Diagnostics'), Icons.travel_explore_rounded, _diagnostics),
      _act(tr('Тесты', 'Tests'), Icons.speed_rounded, _tests),
      _act(tr('Обновить IPSet', 'Update IPSet'), Icons.cached_rounded, () async {
        final r = await _zapret.updateIpset(_zapret.zapretDir);
        ToastService.show(r, Icons.cached_rounded);
      }),
      _act(tr('Проверить Hosts', 'Check Hosts'), Icons.fact_check_rounded, () async {
        await Process.run('powershell', ['-Command',
          'Start-Process notepad -ArgumentList \'C:\\Windows\\System32\\drivers\\etc\\hosts\' -Verb RunAs']);
        ToastService.show(tr('Hosts открыт', 'Hosts opened'), Icons.fact_check_rounded);
      }),
_act(tr('Обновления ПО', 'Software Updates'), Icons.new_releases_rounded, () async {
  final c = await UpdateService.check();
  if (c.release != null) {
    NotifyService.push(
      'Доступно обновление ${c.release!.version} — тапни, чтобы установить',
      icon: Icons.system_update_rounded,
      onTap: () => UpdateService.startUpdate(c.release!),
    );
  } else {
    ToastService.show(
        c.message ?? tr('Обновлений нет', 'No updates'),
        Icons.new_releases_rounded);
  }
}),
      _act(tr('Обновления Zapret', 'Zapret Updates'), Icons.cloud_rounded, () async {
        final r = await _zapret.checkZapretUpdate();
        ToastService.show(r, Icons.cloud_rounded);
      }),
      _act(tr('Скачать Zapret', 'Download Zapret'), Icons.download_rounded, _download),
    ],
  ));

  Widget _act(String label, IconData icon, Future<void> Function() onTap) => Padding(
    padding: EdgeInsets.only(bottom: sc(6)),
    child: Btn25D(
      base: t.surface,
      radius: 999,
      onTap: () => _guard(onTap),
      padding: EdgeInsets.symmetric(vertical: sc(7), horizontal: sc(12)),
      child: Row(children: [
        Icon(icon, size: sc(14), color: t.accent),
        SizedBox(width: sc(8)),
        Expanded(child: Text(label,
          style: TextStyle(fontSize: sc(11), color: t.text, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis)),
      ]),
    ),
  );

  Future<void> _download() async {
    final r = await _zapret.downloadZapret(_zapret.zapretDir,
      onProgress: (p, stage) {
        NotifyService.push(stage,
          icon: Icons.download_rounded, sound: false, progress: p);
      });
    NotifyService.push(r, icon: Icons.download_rounded);
    await _refresh();
  }

  Future<void> _diagnostics() async {
    NotifyService.push(tr('Диагностика...', 'Diagnostics...'),
      icon: Icons.travel_explore_rounded, sound: false);
    final lines = <_Res>[];
    Future<String> run(String exe, List<String> a) async {
      try {
        final r = await Process.run(exe, a, runInShell: true);
        return '${r.stdout}';
      } catch (e) {
        return '$e';
      }
    }
    final bfe = await run('sc', ['query', 'BFE']);
    lines.add(_Res(bfe.contains('RUNNING'), 'Base Filtering Engine running'));
    final proxy = await run('reg', ['query', r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings', '/v', 'ProxyEnable']);
    final proxyOn = RegExp(r'ProxyEnable\s+REG_DWORD\s+0x1').hasMatch(proxy);
    lines.add(_Res(!proxyOn, proxyOn ? 'System proxy ENABLED' : 'System proxy disabled'));
    final wl = await run('tasklist', ['/FI', 'IMAGENAME eq winws.exe', '/NH']);
    lines.add(_Res(wl.contains('winws.exe'), 'Bypass (winws.exe) running'));
    var sysOk = false;
    try {
      sysOk = Directory('${_zapret.zapretDir}\\bin').listSync().any((e) => e.path.toLowerCase().endsWith('.sys'));
    } catch (_) {}
    lines.add(_Res(sysOk, 'WinDivert64.sys present in bin/'));
    try {
      final hosts = await File(r'C:\Windows\System32\drivers\etc\hosts').readAsString();
      lines.add(_Res(!hosts.contains('youtube.com'), 'hosts file clean'));
    } catch (_) {
      lines.add(_Res(false, 'hosts not readable'));
    }
    if (mounted) {
      NotifyService.push(tr('Диагностика', 'Diagnostics'),
        icon: Icons.travel_explore_rounded,
        lines: lines.map((r) => NotifyLine(r.ok, r.text)).toList());
    }
  }

  Future<void> _tests() async {
    NotifyService.push(tr('Тесты...', 'Tests...'),
      icon: Icons.speed_rounded, sound: false);
    final lines = <_Res>[
      await _probe('https://www.google.com', 'Google'),
      await _probe('https://discord.com', 'Discord'),
      await _probe('https://www.youtube.com', 'YouTube'),
    ];
    if (mounted) {
      NotifyService.push(tr('Тесты', 'Tests'),
        icon: Icons.speed_rounded,
        lines: lines.map((r) => NotifyLine(r.ok, r.text)).toList());
    }
  }

  Future<_Res> _probe(String url, String name) async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8)
        ..findProxy = (u) => 'DIRECT';
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set('User-Agent', 'Z2-Mini');
      final resp = await req.close();
      await resp.drain<void>();
      client.close();
      return _Res(resp.statusCode < 500, '$name · HTTP ${resp.statusCode}');
    } catch (_) {
      return _Res(false, '$name · unreachable');
    }
  }
}

class _Res {
  final bool ok;
  final String text;
  _Res(this.ok, this.text);
}

class AnimatedSwitchedText extends StatelessWidget {
  final bool open;
  final String summary;
  final AppTheme theme;
  const AnimatedSwitchedText({super.key, required this.open, required this.summary, required this.theme});

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeOutCubic,
    alignment: Alignment.topCenter,
    child: open
        ? const SizedBox.shrink()
        : Text(summary, style: TextStyle(fontSize: sc(10), color: theme.text.withOpacity(0.55))),
  );
}