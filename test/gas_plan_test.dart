import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gaslink_app/core/theme.dart';
import 'package:gaslink_app/screens/consumer/gas_plan_screen.dart';

Widget _wrap(Widget child, Brightness brightness) {
  return MaterialApp(
    theme: buildAppTheme(brightness),
    locale: const Locale('sw'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  testWidgets('GasPlan teaser renders the pitch and interest CTA',
      (tester) async {
    await tester.pumpWidget(_wrap(const GasPlanScreen(), Brightness.light));
    await tester.pump();

    expect(find.textContaining('GasPlan kwa Waajiriwa'), findsWidgets);
    expect(
      find.textContaining('Malipo kupitia payslip'),
      findsOneWidget,
    );
    expect(find.textContaining('Inakuja hivi karibuni'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Ongea nasi'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('Ongea nasi'), findsOneWidget);
    expect(find.text('Shiriki na HR yako'), findsOneWidget);
  });

  testWidgets('GasPlan teaser renders in dark mode without exceptions',
      (tester) async {
    await tester.pumpWidget(_wrap(const GasPlanScreen(), Brightness.dark));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
