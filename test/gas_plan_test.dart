import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gaslink_app/core/theme.dart';
import 'package:gaslink_app/screens/consumer/gas_plan_screen.dart';

void main() {
  testWidgets('GasPlan teaser renders the pitch and interest CTA',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const GasPlanScreen(),
      ),
    );
    await tester.pump();

    expect(find.textContaining('GasPlan kwa Waajiriwa'), findsWidgets);
    expect(
      find.textContaining('Malipo kupitia payslip'),
      findsOneWidget,
    );
    expect(find.textContaining('Inakuja hivi karibuni'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Ongea nasi / Register interest'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('Ongea nasi / Register interest'), findsOneWidget);
    expect(find.text('Share with your HR'), findsOneWidget);
  });

  testWidgets('GasPlan teaser renders in dark mode without exceptions',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        home: const GasPlanScreen(),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
