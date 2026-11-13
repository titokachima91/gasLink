import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gaslink_app/core/constants.dart';
import 'package:gaslink_app/core/theme.dart';
import 'package:gaslink_app/screens/about_screen.dart';
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
  testWidgets('about screen shows version, legal, and support', (tester) async {
    await tester.pumpWidget(wrap(Brightness.light, const AboutScreen()));
    await tester.pump();

    expect(find.text('Toleo / Version ${AppConstants.appVersion}'),
        findsOneWidget);
    expect(find.text('Vigezo na Masharti / Terms & Conditions'), findsOneWidget);
    expect(find.text('Sera ya Faragha / Privacy Policy'), findsOneWidget);
    expect(find.text('+255767304776'), findsOneWidget);
    expect(find.text('support@gaslink.co.tz'), findsOneWidget);
  });

  testWidgets('about screen opens the terms page', (tester) async {
    await tester.pumpWidget(wrap(Brightness.light, const AboutScreen()));
    await tester.pump();

    await tester.tap(find.text('Vigezo na Masharti / Terms & Conditions'));
    await tester.pumpAndSettle();

    expect(find.byType(TermsScreen), findsOneWidget);
  });

  testWidgets('about screen renders in dark mode without exceptions',
      (tester) async {
    await tester.pumpWidget(wrap(Brightness.dark, const AboutScreen()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
