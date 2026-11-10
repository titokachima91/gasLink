import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_preferences.dart';

/// Initial theme mode loaded from disk before the app starts.
///
/// Overridden in [main] with the persisted value. Defaults to
/// [ThemeMode.system] when no preference has been saved.
final initialThemeModeProvider = Provider<ThemeMode>(
  (ref) => ThemeMode.system,
);

/// Riverpod notifier that manages the current [ThemeMode].
final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController(ref.watch(initialThemeModeProvider));
});

/// State notifier that manages the current [ThemeMode].
///
/// Changes are applied immediately and persisted for the next launch.
class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController([ThemeMode initial = ThemeMode.system]) : super(initial);

  /// Sets the theme mode to the specified value and saves it.
  Future<void> setMode(ThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    await ThemePreferences.saveThemeMode(mode);
  }

  /// Toggles between light and dark mode.
  void toggle() {
    setMode(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }
}
