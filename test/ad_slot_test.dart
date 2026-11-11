import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gaslink_app/core/theme.dart';
import 'package:gaslink_app/models/ad_models.dart';
import 'package:gaslink_app/services/ad_service.dart';
import 'package:gaslink_app/widgets/ad_slot.dart';

AdPlacement placement({
  String audience = 'consumer',
  bool active = true,
  String title = 'Oryx Promo',
}) =>
    AdPlacement(
      id: 'p1',
      title: title,
      subtitle: 'Bei nafuu wiki hii',
      ctaText: 'Ona',
      linkUrl: 'https://example.com',
      active: active,
      audience: audience,
    );

void main() {
  test('audience matching targets the right roles', () {
    expect(AdService.matchesAudience('consumer', 'consumer'), isTrue);
    expect(AdService.matchesAudience('consumer', 'guest'), isTrue);
    expect(AdService.matchesAudience('consumer', 'vendor'), isFalse);
    expect(AdService.matchesAudience('vendor', 'vendor'), isTrue);
    expect(AdService.matchesAudience('vendor', 'consumer'), isFalse);
    expect(AdService.matchesAudience('both', 'vendor'), isTrue);
    expect(AdService.matchesAudience('both', null), isTrue);
  });

  testWidgets('shows the advertise-here placeholder when no campaign exists',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: AdSlot(
            placementId: 'test',
            role: 'consumer',
            loader: () async => null,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Advertise Here'), findsOneWidget);
  });

  testWidgets('renders an active campaign for the matching audience',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: AdSlot(
            placementId: 'test',
            role: 'consumer',
            loader: () async => placement(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Oryx Promo'), findsOneWidget);
    expect(find.text('Ona'), findsOneWidget);
    expect(find.textContaining('Advertise Here'), findsNothing);
  });

  testWidgets('hides consumer campaigns from vendors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: AdSlot(
            placementId: 'test',
            role: 'vendor',
            loader: () async => placement(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Oryx Promo'), findsNothing);
    expect(find.textContaining('Advertise Here'), findsOneWidget);
  });

  testWidgets('dismissing the banner hides it for the session', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: AdSlot(
            placementId: 'test',
            role: 'consumer',
            loader: () async => placement(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Oryx Promo'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(find.text('Oryx Promo'), findsNothing);
  });

  testWidgets('renders the banner in dark mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        home: Scaffold(
          body: AdSlot(
            placementId: 'test-dark',
            role: 'consumer',
            loader: () async => placement(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Oryx Promo'), findsOneWidget);
  });
}
