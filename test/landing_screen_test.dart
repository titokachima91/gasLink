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
    expect(find.text('Pata Gesi / Get Gas'), findsOneWidget);
    expect(find.text('Chunguza kama mgeni / Explore as guest'), findsOneWidget);
    expect(find.text('Advertise Here'), findsOneWidget);
    expect(find.textContaining('Inavyofanya kazi'), findsOneWidget);
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
