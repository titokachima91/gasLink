// lib/core/locale_controller.dart
// Riverpod controller for the app language, mirroring ThemeController.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_locale.dart';
import 'locale_preferences.dart';

/// Initial language loaded from disk before the app starts.
///
/// Overridden in [main] with the persisted value. Defaults to
/// [AppLocale.system] when no preference has been saved.
final initialLocaleProvider = Provider<AppLocale>(
  (ref) => AppLocale.system,
);

/// Riverpod notifier that manages the current [AppLocale].
final localeControllerProvider =
    StateNotifierProvider<LocaleController, AppLocale>((ref) {
  return LocaleController(ref.watch(initialLocaleProvider));
});

/// State notifier that manages the current [AppLocale].
///
/// Changes are applied immediately and persisted for the next launch.
class LocaleController extends StateNotifier<AppLocale> {
  LocaleController([AppLocale initial = AppLocale.system]) : super(initial);

  /// Sets the language and saves it.
  Future<void> setLocale(AppLocale locale) async {
    if (locale == state) return;
    state = locale;
    await LocalePreferences.saveLocale(locale);
  }
}
