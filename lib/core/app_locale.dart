// lib/core/app_locale.dart
// The languages the app supports plus the "follow the system" option.

import 'package:flutter/widgets.dart';

enum AppLocale { system, sw, en }

extension AppLocaleX on AppLocale {
  /// Locale passed to [MaterialApp]. Null means "use the device locale";
  /// Flutter then falls back to Kiswahili for unsupported languages.
  Locale? get locale => switch (this) {
        AppLocale.system => null,
        AppLocale.sw => const Locale('sw'),
        AppLocale.en => const Locale('en'),
      };

  String get storageKey => switch (this) {
        AppLocale.system => 'system',
        AppLocale.sw => 'sw',
        AppLocale.en => 'en',
      };
}
