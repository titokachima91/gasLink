import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gaslink_app/widgets/root_back_guard.dart';

Widget wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('sw'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: const [Locale('sw'), Locale('en')],
    home: child,
  );
}

void main() {
  testWidgets('root back guard runs onBack when provided', (tester) async {
    var called = false;
    await tester.pumpWidget(
      wrap(
        RootBackGuard(
          onBack: () async {
            called = true;
          },
          child: const Scaffold(body: Text('root')),
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(called, isTrue);
    expect(find.text('root'), findsOneWidget);
  });

  testWidgets('root back guard asks before exiting', (tester) async {
    await tester.pumpWidget(
      wrap(
        const RootBackGuard(
          child: Scaffold(body: Text('root')),
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Funga app'), findsOneWidget);
    expect(find.text('Ghairi'), findsOneWidget);
    expect(find.text('Ndiyo, funga'), findsOneWidget);

    await tester.tap(find.text('Ghairi'));
    await tester.pumpAndSettle();
    expect(find.text('Funga app'), findsNothing);
  });
}
