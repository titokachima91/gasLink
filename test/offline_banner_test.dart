import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gaslink_app/core/theme.dart';
import 'package:gaslink_app/widgets/offline_banner.dart';

void main() {
  testWidgets('offline banner appears offline and hides when online',
      (tester) async {
    final controller = StreamController<List<ConnectivityResult>>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: OfflineBanner(stream: controller.stream),
        ),
      ),
    );

    expect(find.textContaining('You are offline'), findsNothing);

    controller.add([ConnectivityResult.none]);
    await tester.pump();

    expect(find.textContaining('You are offline'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);

    controller.add([ConnectivityResult.wifi]);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('You are offline'), findsNothing);
  });

  testWidgets('offline banner renders in dark mode', (tester) async {
    final controller = StreamController<List<ConnectivityResult>>();
    addTearDown(controller.close);
    controller.add([ConnectivityResult.none]);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        home: Scaffold(body: OfflineBanner(stream: controller.stream)),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
  });
}
