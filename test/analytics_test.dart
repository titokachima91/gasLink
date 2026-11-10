import 'package:flutter_test/flutter_test.dart';
import 'package:gaslink_app/models/analytics.dart';
import 'package:gaslink_app/models/order.dart';
import 'package:gaslink_app/models/vendor.dart';
import 'package:gaslink_app/services/analytics_service.dart';

Order _order({
  required String id,
  required String consumer,
  required String vendor,
  required String status,
  required double total,
  required DateTime created,
  DateTime? delivered,
  String brand = 'Oryx Gas',
  String size = '15kg',
}) {
  return Order(
    id: id,
    consumerUid: consumer,
    vendorId: vendor,
    productId: 'product-$id',
    brand: brand,
    size: size,
    type: 'refill',
    quantity: 1,
    unitPrice: total,
    total: total,
    commissionRate: 0.03,
    commissionDue: total * 0.03,
    status: status,
    deliveryAddress: 'Sinza',
    createdAt: created,
    deliveredAt: delivered,
  );
}

Vendor _vendor(String id, String name, String district, DateTime created) {
  return Vendor(
    id: id,
    businessName: name,
    district: district,
    createdAt: created,
  );
}

void main() {
  final now = DateTime.utc(2026, 11, 11, 12);
  final created = DateTime.utc(2026, 1, 1);

  final orders = [
    _order(
      id: 'o1',
      consumer: 'consumer-a',
      vendor: 'v1',
      status: 'delivered',
      total: 100,
      created: now.subtract(const Duration(days: 1)),
      delivered: now.subtract(const Duration(hours: 23, minutes: 30)),
    ),
    _order(
      id: 'o2',
      consumer: 'consumer-a',
      vendor: 'v1',
      status: 'delivered',
      total: 250,
      created: now.subtract(const Duration(days: 2)),
      delivered: now.subtract(const Duration(days: 2)).add(
            const Duration(hours: 1),
          ),
    ),
    _order(
      id: 'o3',
      consumer: 'consumer-b',
      vendor: 'v2',
      status: 'completed',
      total: 300,
      brand: 'Taifa Gas',
      size: '38kg',
      created: now.subtract(const Duration(days: 3)),
      delivered: now.subtract(const Duration(days: 3)).add(
            const Duration(minutes: 45),
          ),
    ),
    _order(
      id: 'o4',
      consumer: 'consumer-c',
      vendor: 'v1',
      status: 'cancelled',
      total: 400,
      created: now.subtract(const Duration(hours: 8)),
    ),
    _order(
      id: 'o5',
      consumer: 'consumer-d',
      vendor: 'v2',
      status: 'placed',
      total: 500,
      created: now.subtract(const Duration(hours: 2)),
    ),
    _order(
      id: 'old',
      consumer: 'consumer-old',
      vendor: 'v1',
      status: 'delivered',
      total: 999,
      created: now.subtract(const Duration(days: 60)),
      delivered: now.subtract(const Duration(days: 60)).add(
            const Duration(minutes: 10),
          ),
    ),
  ];

  final snapshot = AnalyticsService.compute(
    orders: orders,
    vendors: [
      _vendor('v1', 'Kinondoni Gas', 'Kinondoni', created),
      _vendor('v2', 'Ilala Gas', 'Ilala', created),
    ],
    days: 30,
    now: now,
  );

  test('analytics computes the documented KPIs', () {
    expect(snapshot.totalOrders, 5);
    expect(snapshot.deliveredOrders, 3);
    expect(snapshot.cancelledOrders, 1);
    expect(snapshot.gmv, 650);
    expect(snapshot.aov, closeTo(216.67, 0.01));
    expect(snapshot.completionRate, 0.75);
    expect(snapshot.cancellationRate, 0.2);
    expect(snapshot.avgDeliveryMinutes, closeTo(45, 0.01));
    expect(snapshot.repeatConsumers, 1);
    expect(snapshot.uniqueConsumers, 2);
    expect(snapshot.repeatRate, 0.5);
  });

  test('daily trend covers every day and excludes old orders', () {
    expect(snapshot.dailyTrend.length, 30);
    expect(
      snapshot.dailyTrend
          .fold<int>(0, (running, point) => running + point.orders),
      5,
    );
    expect(
      snapshot.dailyTrend.fold<double>(
        0,
        (running, point) => running + point.gmv,
      ),
      650,
    );
  });

  test('status, vendor and district breakdowns are consistent', () {
    final delivered = snapshot.statusBreakdown
        .firstWhere((item) => item.status == 'delivered');
    expect(delivered.count, 3);
    expect(snapshot.topVendors.first.vendorId, 'v1');
    expect(snapshot.topVendors.first.gmv, 350);
    expect(snapshot.brandDemand.first.label, 'Oryx Gas');
    expect(snapshot.districtPerformance.first.district, 'Kinondoni');
    expect(snapshot.districtPerformance.first.orders, 3);
    expect(snapshot.vendorScorecards.first.fillRate, closeTo(2 / 3, 0.01));
  });

  test('CSV export contains KPIs, trends and scorecards', () {
    final csv = AnalyticsCsv.build(snapshot);
    expect(csv, contains('GMV,650.00'));
    expect(csv, contains('Daily trend'));
    expect(csv, contains('Vendor scorecards'));
    expect(csv, contains('Africa/Dar_es_Salaam'));
    expect(csv, contains('TZS'));
  });

  test('metric definitions are exposed for the UI', () {
    expect(AnalyticsSnapshot.currency, 'TZS');
    expect(AnalyticsSnapshot.timezone, 'Africa/Dar_es_Salaam');
  });
}
