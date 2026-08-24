import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'core/app_visibility.dart';
import 'core/ui_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  UiSettings.load();

  const opts = WindowOptions(
    minimumSize: Size(760, 560),
    center: true,
    title: 'Z2 Mini',
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  await windowManager.waitUntilReadyToShow(opts, () async {
    await windowManager.setPreventClose(true);
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setSize(const Size(1000, 660));
  });
  windowManager.addListener(_CloseHandler());

  try {
    final ru = UiSettings.language.value == 'RU';
    await trayManager.setIcon('assets/lock.ico');
    await trayManager.setToolTip('Z2 Mini');
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: 'show', label: ru ? 'Показать' : 'Show'),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: ru ? 'Выход' : 'Quit'),
    ]));
    trayManager.addListener(_Tray());
  } catch (_) {}

  runApp(const Z2MiniApp());
}

class _CloseHandler with WindowListener {
  @override
  void onWindowClose() async {
    // ⚡ КРИТИЧНО: сохраняем настройки немедленно перед выходом
    UiSettings.saveImmediate();
    if (UiSettings.closeToTray.value) {
      AppVisibility.visible.value = false;
      await windowManager.hide();
    } else {
      await windowManager.destroy();
    }
  }

  @override
  void onWindowMinimize() => AppVisibility.visible.value = false;
  @override
  void onWindowRestore() => AppVisibility.visible.value = true;
  // 💤 как в Z2 Manager: окно не в фокусе — анимации полностью стоят
  @override
  void onWindowBlur() => AppVisibility.visible.value = false;
  @override
  void onWindowFocus() => AppVisibility.visible.value = true;
}

class _Tray with TrayListener {
  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
    AppVisibility.visible.value = true;
  }

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem item) {
    if (item.key == 'show') {
      windowManager.show();
      windowManager.focus();
    }
    if (item.key == 'quit') {
      UiSettings.saveImmediate();
      windowManager.destroy();
    }
  }
}