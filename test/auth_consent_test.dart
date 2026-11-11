import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gaslink_app/core/theme.dart';
import 'package:gaslink_app/screens/auth/login_screen.dart';
import 'package:gaslink_app/screens/auth/widgets/auth_widgets.dart';
import 'package:gaslink_app/screens/legal/legal_screens.dart';

Widget wrap(Brightness brightness, Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: buildAppTheme(brightness),
      home: child,
    ),
  );
}

void main() {
  testWidgets('login button stays disabled until terms are accepted',
      (tester) async {
    await tester.pumpWidget(wrap(Brightness.light, const LoginScreen()));
    await tester.pump();

    FilledButton loginButton() => tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Ingia / Login'),
        );

    expect(loginButton().onPressed, isNull);

    // Accept the terms checkbox (first CheckboxListTile).
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();

    expect(loginButton().onPressed, isNotNull);
  });

  testWidgets('terms link opens the terms page', (tester) async {
    await tester.pumpWidget(wrap(Brightness.light, const LoginScreen()));
    await tester.pump();

    await tester.tap(find.text('Soma'));
    await tester.pumpAndSettle();

    expect(find.byType(TermsScreen), findsOneWidget);
    expect(find.textContaining('Vigezo na Masharti'), findsWidgets);
  });

  testWidgets('ads consent defaults to accepted', (tester) async {
    await tester.pumpWidget(wrap(Brightness.light, const LoginScreen()));
    await tester.pump();

    final checkboxes = tester
        .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
        .toList();
    expect(checkboxes.length, 2);
    expect(checkboxes[0].value, isFalse); // terms
    expect(checkboxes[1].value, isTrue); // ads
  });

  testWidgets('login screen renders in dark mode without exceptions',
      (tester) async {
    await tester.pumpWidget(wrap(Brightness.dark, const LoginScreen()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(AuthConsents), findsOneWidget);
  });
}
