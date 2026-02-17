import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _fontSizeKey = 'font_size';
  static const String _fontHeightKey = 'font_height';

  ThemeMode _themeMode = ThemeMode.system;
  double _fontSize = 18.0;
  double _fontHeight = 1.5;

  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;
  double get fontHeight => _fontHeight;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final savedThemeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[savedThemeIndex];

    final double savedFontSize = prefs.getDouble(_fontSizeKey) ?? 18.0;
    _fontSize = savedFontSize;

    final double savedFontHeight = prefs.getDouble(_fontHeightKey) ?? 1.5;
    _fontHeight = savedFontHeight;

    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, size);
  }

  Future<void> setFontHeight(double height) async {
    _fontHeight = height;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontHeightKey, height);
  }
}
