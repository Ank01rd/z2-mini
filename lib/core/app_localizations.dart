class AppLocalizations {
  final String locale;
  AppLocalizations(this.locale);
  String t(String key) => _getStrings()[key] ?? key;
  
  Map<String, String> _getStrings() => locale == 'EN' ? _en : _ru;

  final Map<String, String> _ru = {
    'home': 'Главная', 'settings': 'Настройки', 'start': 'Запустить', 
    'stop': 'Остановить', 'active': 'Активен', 'stopped': 'Остановлен',
    'selectConfig': 'Выберите конфиг', 'noConfigs': 'Конфиги не найдены',
    'glassSettings': 'Настройки стекла', 'refraction': 'Преломление (Размытие)',
    'edgeGlow': 'Блик по краям', 'radius': 'Скругление', 'tint': 'Оттенок',
    'theme': 'Тема', 'dark': 'Тёмная', 'light': 'Светлая', 'quit': 'Выход', 'show': 'Показать'
  };
  
  final Map<String, String> _en = {
    'home': 'Home', 'settings': 'Settings', 'start': 'Start', 
    'stop': 'Stop', 'active': 'Active', 'stopped': 'Stopped',
    'selectConfig': 'Select config', 'noConfigs': 'No configs found',
    'glassSettings': 'Glass Settings', 'refraction': 'Refraction (Blur)',
    'edgeGlow': 'Edge Glow', 'radius': 'Radius', 'tint': 'Tint',
    'theme': 'Theme', 'dark': 'Dark', 'light': 'Light', 'quit': 'Quit', 'show': 'Show'
  };
}