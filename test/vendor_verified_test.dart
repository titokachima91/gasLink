import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gaslink_app/core/filter_sort.dart';
import 'package:gaslink_app/core/session_data.dart' as session;
import 'package:gaslink_app/core/theme.dart';
import 'package:gaslink_app/models/vendor.dart';
import 'package:gaslink_app/widgets/verified_badge.dart';

void main() {
  test('verification defaults to false and round-trips through the model', () {
    final now = DateTime(2026, 1, 1);
    final unverified = Vendor.fromMap('v1', {
      'businessName': 'New Gas',
      'createdAt': Timestamp.fromDate(now),
    });
    final verified = Vendor.fromMap('v2', {
      'businessName': 'Trusted Gas',
      'createdAt': Timestamp.fromDate(now),
      'verified': true,
      'verifiedAt': Timestamp.fromDate(DateTime(2026, 2, 1)),
      'verifiedBy': 'admin_local',
    });

    expect(unverified.verified, isFalse);
    expect(verified.verified, isTrue);
    expect(verified.isVerified, isTrue);
    expect(verified.verifiedBy, 'admin_local');
    expect(verified.verifiedAt, DateTime(2026, 2, 1));

    final map = verified.toMap();
    expect(map['verified'], isTrue);
    expect(map['verifiedBy'], 'admin_local');
    expect(map['verifiedAt'], isA<Timestamp>());

    final copy = verified.copyWith(status: VendorStatus.suspended);
    expect(copy.verified, isTrue);
  });

  test('verified-only filter uses the stored flag, not phone presence', () {
    const offers = [
      session.VendorOffer(
        vendor: session.Vendor(
          id: 'verified',
          businessName: 'Verified Gas',
          phone: '0712000001',
          area: 'Sinza',
          verified: true,
        ),
        weights: [
          session.WeightOffer(brand: 'Oryx', weight: '6kg', price: 20000)
        ],
        vendorBrands: ['Oryx'],
      ),
      session.VendorOffer(
        vendor: session.Vendor(
          id: 'phone-only',
          businessName: 'Phone Only Gas',
          phone: '0712000002',
          area: 'Sinza',
        ),
        weights: [
          session.WeightOffer(brand: 'Oryx', weight: '6kg', price: 21000)
        ],
        vendorBrands: ['Oryx'],
      ),
    ];

    final filtered = FilterSort.apply(
      offers,
      const FilterCriteria(verifiedOnly: true),
    );

    expect(filtered.map((offer) => offer.vendor.id), ['verified']);
  });

  testWidgets('verified badge renders the icon and optional label',
      (tester) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(brightness),
          home: const Scaffold(
            body: VerifiedBadge(label: 'Verified Vendor'),
          ),
        ),
      );

      expect(find.byIcon(Icons.verified), findsOneWidget);
      expect(find.text('Verified Vendor'), findsOneWidget);
    }
  });

  testWidgets('compact verified badge can render icon-only', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(body: VerifiedBadge(compact: true)),
      ),
    );

    expect(find.byIcon(Icons.verified), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });
}
