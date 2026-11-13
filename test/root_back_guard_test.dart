import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gaslink_app/widgets/root_back_guard.dart';

void main() {
  testWidgets('root back guard runs onBack when provided', (tester) async {
    var called = false;
    await tester.pumpWidget(
      MaterialApp(
        home: RootBackGuard(
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
      const MaterialApp(
        home: RootBackGuard(
          child: Scaffold(body: Text('root')),
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Funga App / Exit App'), findsOneWidget);
    expect(find.text('Hapana / Cancel'), findsOneWidget);
    expect(find.text('Ndiyo / Exit'), findsOneWidget);

    await tester.tap(find.text('Hapana / Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Funga App / Exit App'), findsNothing);
  });
}
