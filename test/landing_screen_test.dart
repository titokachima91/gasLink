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
    expect(find.text('Ingia / Log in'), findsWidgets);
    expect(find.text('Mgeni / Guest'), findsOneWidget);
    expect(find.text('Jiandikishe / Register'), findsOneWidget);
    expect(find.textContaining('Advertise Here'), findsOneWidget);
    expect(find.textContaining('Inavyofanya kazi'), findsOneWidget);

    // The blended login section lives at the bottom of the same page.
    await tester.scrollUntilVisible(
      find.text('Huna akaunti? Jiandikishe / Register'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.byType(TextField), findsNWidgets(2));
    expect(
      find.text('Huna akaunti? Jiandikishe / Register'),
      findsOneWidget,
    );
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
