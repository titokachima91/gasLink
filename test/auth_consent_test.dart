import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gaslink_app/core/theme.dart';
import 'package:gaslink_app/screens/auth/landing_screen.dart';
import 'package:gaslink_app/screens/auth/login_screen.dart';
import 'package:gaslink_app/screens/auth/register_screen.dart';
import 'package:gaslink_app/screens/auth/widgets/auth_widgets.dart';
import 'package:gaslink_app/screens/legal/legal_screens.dart';

Widget wrap(Brightness brightness, Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: buildAppTheme(brightness),
      locale: const Locale('sw'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('sw'), Locale('en')],
      home: child,
    ),
  );
}

void main() {
  testWidgets('login has no consent gate and stays enabled', (tester) async {
    await tester.pumpWidget(wrap(Brightness.light, const LoginScreen()));
    await tester.pump();

    expect(find.byType(CheckboxListTile), findsNothing);

    final loginButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Ingia'),
    );
    expect(loginButton.onPressed, isNotNull);
  });

  testWidgets('login terms link opens the terms page', (tester) async {
    await tester.pumpWidget(wrap(Brightness.light, const LoginScreen()));
    await tester.pump();

    await tester.tap(find.text('Vigezo na Masharti'));
    await tester.pumpAndSettle();

    expect(find.byType(TermsScreen), findsOneWidget);
    expect(find.textContaining('Vigezo na Masharti'), findsWidgets);
  });

  testWidgets('login back returns to the landing page', (tester) async {
    await tester.pumpWidget(wrap(Brightness.light, const LoginScreen()));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(LandingScreen), findsOneWidget);
  });

  testWidgets('registration requires terms and marketing consent defaults off',
      (tester) async {
    await tester.pumpWidget(wrap(Brightness.light, const RegisterScreen()));
    await tester.pump();

    final checkboxes = tester
        .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
        .toList();
    expect(checkboxes.length, 2);
    expect(checkboxes[0].value, isFalse); // terms
    expect(checkboxes[1].value, isFalse); // marketing push consent

    FilledButton createButton() => tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Fungua akaunti'),
        );
    expect(createButton().onPressed, isNull);

    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();

    expect(createButton().onPressed, isNotNull);
    final after = tester
        .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
        .toList();
    expect(after[1].value, isFalse);
  });

  testWidgets('register screen renders in dark mode without exceptions',
      (tester) async {
    await tester.pumpWidget(wrap(Brightness.dark, const RegisterScreen()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(AuthConsents), findsOneWidget);
  });
}
