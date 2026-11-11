import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gaslink_app/core/theme.dart';
import 'package:gaslink_app/screens/auth/landing_screen.dart';

void main() {
  testWidgets('landing page renders hero, props, steps, and CTAs',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const LandingScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('GasLink'), findsOneWidget);
    expect(find.text('Ingia / Log in'), findsOneWidget);
    expect(find.text('Mgeni / Guest'), findsOneWidget);
    expect(find.text('Jiandikishe / Register'), findsOneWidget);
    expect(find.textContaining('Advertise Here'), findsOneWidget);
    expect(find.textContaining('Inavyofanya kazi'), findsOneWidget);

    // No form on the landing page — login lives on its own screen.
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('landing page renders in dark mode without exceptions',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        home: const LandingScreen(),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('GasLink'), findsOneWidget);
  });
}
