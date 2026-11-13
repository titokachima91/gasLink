// lib/l10n/localized_messages.dart
// Resolves AppLocalizations outside the widget tree (for SMS/push payloads)
// using the persisted language choice. Falls back to Kiswahili.

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../core/app_locale.dart';
import '../core/locale_preferences.dart';

Future<AppLocalizations> loadLocalizedMessages() async {
  try {
    final preference = await LocalePreferences.readLocale();
    final languageCode = switch (preference) {
      AppLocale.en => 'en',
      AppLocale.sw => 'sw',
      AppLocale.system =>
        PlatformDispatcher.instance.locale.languageCode == 'en' ? 'en' : 'sw',
    };
    return lookupAppLocalizations(Locale(languageCode));
  } catch (_) {
    // Persistence is best-effort; never block an order on locale lookup.
    return lookupAppLocalizations(const Locale('sw'));
  }
}
