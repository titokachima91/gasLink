import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gaslink_app/app.dart';
import 'package:gaslink_app/core/app_colors.dart';
import 'package:gaslink_app/core/theme.dart';
import 'package:gaslink_app/core/theme_controller.dart';
import 'package:gaslink_app/core/theme_preferences.dart';
import 'package:gaslink_app/core/theme_status_colors.dart';
import 'package:gaslink_app/screens/auth/login_screen.dart';

void main() {
  testWidgets('app starts inside a ProviderScope and renders the login screen',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialThemeModeProvider.overrideWithValue(ThemeMode.system),
        ],
        child: const GasLinkApp(),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('app renders in dark mode when the persisted mode is dark',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialThemeModeProvider.overrideWithValue(ThemeMode.dark),
        ],
        child: const GasLinkApp(),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final context = tester.element(find.byType(LoginScreen));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(
      Theme.of(context).appBarTheme.backgroundColor,
      AppColors.appBarDark,
    );
  });

  test('light and dark themes use the correct brightness and colors', () {
    final light = buildAppTheme(Brightness.light);
    final dark = buildAppTheme(Brightness.dark);

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.scaffoldBackgroundColor, AppColors.background);
    expect(dark.scaffoldBackgroundColor, AppColors.darkBackground);
    expect(dark.colorScheme.onSurface, AppColors.onDarkSurface);
    expect(light.appBarTheme.backgroundColor, AppColors.primary);
    expect(dark.appBarTheme.backgroundColor, AppColors.appBarDark);
    expect(light.appBarTheme.foregroundColor, Colors.white);
    expect(dark.appBarTheme.foregroundColor, Colors.white);
  });

  test('both themes register the GasLink status-color extension', () {
    final light = buildAppTheme(Brightness.light);
    final dark = buildAppTheme(Brightness.dark);

    final lightStatus = light.extension<GasLinkStatusColors>();
    final darkStatus = dark.extension<GasLinkStatusColors>();

    expect(lightStatus, isNotNull);
    expect(darkStatus, isNotNull);
    expect(lightStatus!.success, GasLinkStatusColors.light.success);
    expect(darkStatus!.success, GasLinkStatusColors.dark.success);
    expect(lightStatus.success, isNot(darkStatus.success));
    expect(lightStatus.warning, isNot(darkStatus.warning));
    expect(lightStatus.info, isNot(darkStatus.info));
  });

  test('screens and widgets no longer contain legacy hardcoded colors', () {
    const legacyTokens = <String>[
      'Colors.orange',
      'Colors.black87',
      'Colors.black54',
      'Colors.grey',
      '0xFFF8F9FA',
    ];

    final violations = <String>[];
    for (final directory in [
      Directory('lib/screens'),
      Directory('lib/widgets'),
    ]) {
      for (final entity in directory.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        for (final token in legacyTokens) {
          if (source.contains(token)) {
            violations.add('${entity.path}: $token');
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Use context.colors / context.gasColors instead: '
          '${violations.join(', ')}',
    );
  });

  test('theme controller changes mode and persists it', () async {
    SharedPreferences.setMockInitialValues({});

    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(themeControllerProvider), ThemeMode.system);

    await container.read(themeControllerProvider.notifier).setMode(ThemeMode.dark);

    expect(container.read(themeControllerProvider), ThemeMode.dark);
    expect(await ThemePreferences.readThemeMode(), ThemeMode.dark);
  });
}
