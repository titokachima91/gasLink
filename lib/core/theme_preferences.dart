import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's [ThemeMode] selection with [SharedPreferences].
class ThemePreferences {
  const ThemePreferences._();

  /// Key used to store the theme mode in persistent storage.
  static const String key = 'theme_mode';

  /// Reads the saved theme mode, falling back to [ThemeMode.system].
  static Future<ThemeMode> readThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return _fromName(prefs.getString(key));
  }

  /// Saves the theme mode to persistent storage.
  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, mode.name);
  }

  static ThemeMode _fromName(String? name) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => ThemeMode.system,
    );
  }
}
