import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gaslink_app/core/app_locale.dart';
import 'package:gaslink_app/core/locale_controller.dart';
import 'package:gaslink_app/core/locale_preferences.dart';
import 'package:gaslink_app/core/theme.dart';
import 'package:gaslink_app/widgets/language_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('locale preference round-trips and defaults to system', () async {
    expect(await LocalePreferences.readLocale(), AppLocale.system);

    await LocalePreferences.saveLocale(AppLocale.en);
    expect(await LocalePreferences.readLocale(), AppLocale.en);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(LocalePreferences.key), 'en');
  });

  test('controller persists the selected locale', () async {
    final container = ProviderContainer(
      overrides: [
        initialLocaleProvider.overrideWithValue(AppLocale.system),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(localeControllerProvider), AppLocale.system);

    await container
        .read(localeControllerProvider.notifier)
        .setLocale(AppLocale.sw);

    expect(container.read(localeControllerProvider), AppLocale.sw);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(LocalePreferences.key), 'sw');
  });

  test('system resolves to null and explicit locales are sw/en', () {
    expect(AppLocale.system.locale, isNull);
    expect(AppLocale.sw.locale, const Locale('sw'));
    expect(AppLocale.en.locale, const Locale('en'));
  });

  testWidgets('language picker switches the app locale and label',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialLocaleProvider.overrideWithValue(AppLocale.en),
        ],
        child: const _LocaleHarness(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    expect(find.text('Choose language'), findsOneWidget);

    await tester.tap(find.text('Kiswahili'));
    await tester.pumpAndSettle();

    expect(find.text('Lugha'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(LocalePreferences.key), 'sw');
  });
}

class _LocaleHarness extends ConsumerWidget {
  const _LocaleHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    return MaterialApp(
      theme: buildAppTheme(Brightness.light),
      locale: locale.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('sw'), Locale('en')],
      home: const Scaffold(body: LanguagePickerTile()),
    );
  }
}
