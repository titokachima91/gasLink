// lib/core/locale_preferences.dart
// Persists the user's language choice with SharedPreferences.

import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale.dart';

class LocalePreferences {
  const LocalePreferences._();

  /// Key used to store the language selection in persistent storage.
  static const String key = 'app_locale';

  /// Reads the saved language, falling back to the device language.
  static Future<AppLocale> readLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return fromStorageKey(prefs.getString(key));
  }

  /// Saves the language selection to persistent storage.
  static Future<void> saveLocale(AppLocale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, locale.storageKey);
  }

  static AppLocale fromStorageKey(String? value) {
    return AppLocale.values.firstWhere(
      (locale) => locale.storageKey == value,
      orElse: () => AppLocale.system,
    );
  }
}
