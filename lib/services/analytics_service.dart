import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../core/constants.dart';
import '../models/analytics.dart';
import '../models/order.dart';
import '../models/vendor.dart';

/// Operational analytics for the admin console.
///
/// Metric definitions live here so dashboards, scorecards and exports cannot
/// drift apart:
/// - GMV: delivered order totals
/// - AOV: GMV / delivered orders
/// - Completion: delivered / (delivered + cancelled)
/// - Cancellation: cancelled / all orders in range
/// - Delivery time: deliveredAt - createdAt for delivered orders
/// - Repeat rate: consumers with 2+ delivered orders / consumers with a delivery
/// - Fill rate: accepted orders / orders received
///
/// Client-side aggregation is a pilot-stage choice. The query is date-bounded
/// and capped; daily rollups belong in the scale-hardening phase.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  static const Duration eatOffset = Duration(hours: 3);
  static const int maxOrdersPerQuery = 2000;

  /// Latest allowed wall-clock date in the reporting timezone.
  static DateTime eatDate(DateTime value) => value.toUtc().add(eatOffset);

  /// Start of the reporting range as an EAT wall-clock date encoded in UTC.
  static DateTime rangeStart(int days, {DateTime? now}) {
    final today = eatDate(now ?? DateTime.now());
    return DateTime.utc(today.year, today.month, today.day)
        .subtract(Duration(days: days - 1));
  }

  /// Actual UTC instant corresponding to an EAT wall-clock date.
  static DateTime utcStart(DateTime eatWallClock) =>
      eatWallClock.subtract(eatOffset);

  static DateTime _dayOf(DateTime utcValue) {
    final eat = eatDate(utcValue);
    return DateTime.utc(eat.year, eat.month, eat.day);
  }

  static String _key(DateTime day) => '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static bool _isDelivered(String status) => status == 'delivered';
  static bool _isCancelled(String status) => status == 'cancelled';
  static bool _isAccepted(String status) => const {
        'confirmed',
        'on_the_way',
        'delivered_pending',
        'delivered',
      }.contains(status);

  static String normalizeStatus(String raw) {
    final value = raw.trim().toLowerCase();
    if (value == 'completed') return 'delivered';
    if (value == 'accepted') return 'confirmed';
    if (value == 'pending') return 'placed';
    if (value == 'in_transit') return 'on_the_way';
    return value;
  }

  Future<AnalyticsSnapshot> load({int days = 30}) async {
    final now = DateTime.now();
    final start = rangeStart(days, now: now);
    final db = FirebaseFirestore.instance;

    final orderSnap = await db
        .collection('orders')
        .where('created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(utcStart(start)))
        .limit(maxOrdersPerQuery)
        .get();

    final vendorSnap = await db.collection('vendors').get();

    return compute(
      orders: orderSnap.docs.map(Order.fromDoc),
      vendors: vendorSnap.docs.map(Vendor.fromDoc),
      days: days,
      now: now,
    );
  }

  static AnalyticsSnapshot compute({
    required Iterable<Order> orders,
    required Iterable<Vendor> vendors,
    required int days,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final startEat = rangeStart(days, now: current);
    final startUtc = utcStart(startEat);
    final vendorById = {for (final vendor in vendors) vendor.id: vendor};

    final inRange = orders
        .where((order) => !order.createdAt.toUtc().isBefore(startUtc))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final delivered = inRange
        .where((order) => _isDelivered(normalizeStatus(order.status)))
        .toList();
    final cancelled = inRange
        .where((order) => _isCancelled(normalizeStatus(order.status)))
        .toList();

    final gmv =
        delivered.fold<double>(0, (running, order) => running + order.total);
    final aov = delivered.isEmpty ? 0.0 : gmv / delivered.length;

    final deliveryMinutes = <double>[];
    for (final order in delivered) {
      final finished = order.deliveredAt;
      if (finished == null) continue;
      final minutes = finished.difference(order.createdAt).inMinutes;
      if (minutes >= 0) deliveryMinutes.add(minutes.toDouble());
    }
    final avgDelivery = deliveryMinutes.isEmpty
        ? 0.0
        : deliveryMinutes.reduce((a, b) => a + b) / deliveryMinutes.length;

    final deliveredConsumers = <String, int>{};
    for (final order in delivered) {
      if (order.consumerUid.isEmpty) continue;
      deliveredConsumers[order.consumerUid] =
          (deliveredConsumers[order.consumerUid] ?? 0) + 1;
    }
    final repeatConsumers =
        deliveredConsumers.values.where((visits) => visits >= 2).length;

    final trend = <DailyOrderPoint>[];
    for (var i = 0; i < days; i++) {
      trend.add(DailyOrderPoint(
        date: startEat.add(Duration(days: i)),
        orders: 0,
        gmv: 0,
      ));
    }
    final trendByKey = {for (final point in trend) _key(point.date): point};
    final trendCounts = <String, int>{};
    final trendGmv = <String, double>{};
    for (final order in inRange) {
      final key = _key(_dayOf(order.createdAt));
      if (!trendByKey.containsKey(key)) continue;
      trendCounts[key] = (trendCounts[key] ?? 0) + 1;
      if (_isDelivered(normalizeStatus(order.status))) {
        trendGmv[key] = (trendGmv[key] ?? 0) + order.total;
      }
    }
    final updatedTrend = [
      for (final point in trend)
        DailyOrderPoint(
          date: point.date,
          orders: trendCounts[_key(point.date)] ?? 0,
          gmv: trendGmv[_key(point.date)] ?? 0,
        ),
    ];

    final statusCounts = <String, int>{};
    for (final order in inRange) {
      final status = normalizeStatus(order.status);
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }
    final statusBreakdown = <StatusCount>[];
    final seenStatuses = <String>{};
    for (final status in AppConstants.orderStatuses) {
      final frequency = statusCounts[status] ?? 0;
      statusBreakdown.add(StatusCount(status: status, count: frequency));
      seenStatuses.add(status);
    }
    statusCounts.forEach((status, frequency) {
      if (!seenStatuses.contains(status)) {
        statusBreakdown.add(StatusCount(status: status, count: frequency));
      }
    });

    final demandByVendor = <String, List<Order>>{};
    for (final order in inRange) {
      (demandByVendor[order.vendorId] ??= []).add(order);
    }

    final scorecards = <VendorPerformance>[];
    demandByVendor.forEach((vendorId, vendorOrders) {
      final vendor = vendorById[vendorId];
      final completed = vendorOrders
          .where((order) => _isDelivered(normalizeStatus(order.status)))
          .toList();
      final cancelledCount = vendorOrders
          .where((order) => _isCancelled(normalizeStatus(order.status)))
          .length;
      final accepted = vendorOrders
          .where((order) => _isAccepted(normalizeStatus(order.status)))
          .length;
      final vendorGmv =
          completed.fold<double>(0, (running, order) => running + order.total);
      final durations = completed
          .where((order) => order.deliveredAt != null)
          .map((order) =>
              order.deliveredAt!.difference(order.createdAt).inMinutes)
          .where((minutes) => minutes >= 0)
          .toList();
      scorecards.add(VendorPerformance(
        vendorId: vendorId,
        name: vendor?.displayName ?? 'Unknown vendor',
        district: vendor?.district.isNotEmpty == true
            ? vendor!.district
            : 'Unassigned',
        orders: vendorOrders.length,
        delivered: completed.length,
        cancelled: cancelledCount,
        gmv: vendorGmv,
        fillRate: vendorOrders.isEmpty ? 0 : accepted / vendorOrders.length,
        avgDeliveryMinutes: durations.isEmpty
            ? 0
            : durations.reduce((a, b) => a + b) / durations.length,
      ));
    });
    scorecards.sort((a, b) => b.orders.compareTo(a.orders));

    final topVendors = [...scorecards]..sort((a, b) => b.gmv.compareTo(a.gmv));

    final brandCounts = <String, int>{};
    final sizeCounts = <String, int>{};
    for (final order in inRange) {
      final brand = order.brand.trim().isEmpty ? 'Unknown' : order.brand.trim();
      final size = order.size.trim().isEmpty ? 'Unknown' : order.size.trim();
      brandCounts[brand] = (brandCounts[brand] ?? 0) + 1;
      sizeCounts[size] = (sizeCounts[size] ?? 0) + 1;
    }

    List<DemandCount> ranked(Map<String, int> counts) {
      final list = counts.entries
          .map((entry) => DemandCount(label: entry.key, count: entry.value))
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count));
      return list.take(8).toList();
    }

    final districtStats = <String, List<Order>>{};
    for (final order in inRange) {
      final vendor = vendorById[order.vendorId];
      final district =
          vendor?.district.isNotEmpty == true ? vendor!.district : 'Unassigned';
      (districtStats[district] ??= []).add(order);
    }
    final districts = districtStats.entries.map((entry) {
      final districtOrders = entry.value;
      final completed = districtOrders
          .where((order) => _isDelivered(normalizeStatus(order.status)))
          .toList();
      return DistrictPerformance(
        district: entry.key,
        orders: districtOrders.length,
        delivered: completed.length,
        gmv: completed.fold<double>(
            0, (running, order) => running + order.total),
      );
    }).toList()
      ..sort((a, b) => b.orders.compareTo(a.orders));

    final repeatRate = deliveredConsumers.isEmpty
        ? 0.0
        : repeatConsumers / deliveredConsumers.length;

    return AnalyticsSnapshot(
      days: days,
      from: startEat,
      to: current,
      totalOrders: inRange.length,
      deliveredOrders: delivered.length,
      cancelledOrders: cancelled.length,
      gmv: gmv,
      aov: aov,
      completionRate: delivered.isEmpty && cancelled.isEmpty
          ? 0
          : delivered.length / (delivered.length + cancelled.length),
      cancellationRate: inRange.isEmpty ? 0 : cancelled.length / inRange.length,
      avgDeliveryMinutes: avgDelivery,
      repeatRate: repeatRate,
      repeatConsumers: repeatConsumers,
      uniqueConsumers: deliveredConsumers.length,
      dailyTrend: updatedTrend,
      statusBreakdown: statusBreakdown,
      topVendors: topVendors.take(5).toList(),
      brandDemand: ranked(brandCounts),
      sizeDemand: ranked(sizeCounts),
      districtPerformance: districts,
      vendorScorecards: scorecards.take(20).toList(),
    );
  }
}

/// CSV serialisation kept next to the metric definitions.
class AnalyticsCsv {
  AnalyticsCsv._();

  static String build(AnalyticsSnapshot snapshot) {
    final rows = <List<Object?>>[];
    void section(String title) {
      if (rows.isNotEmpty) rows.add(const []);
      rows.add([title]);
    }

    void header(List<Object?> values) => rows.add(values);

    section('GasLink operational analytics');
    header(['Metric', 'Value']);
    header(['Generated at', DateTime.now().toIso8601String()]);
    header(['Range days', snapshot.days]);
    header(['Range start', snapshot.from.toIso8601String()]);
    header(['Range end', snapshot.to.toIso8601String()]);
    header(['Timezone', AnalyticsSnapshot.timezone]);
    header(['Currency', AnalyticsSnapshot.currency]);
    header(['Total orders', snapshot.totalOrders]);
    header(['Delivered orders', snapshot.deliveredOrders]);
    header(['Cancelled orders', snapshot.cancelledOrders]);
    header(['GMV', snapshot.gmv.toStringAsFixed(2)]);
    header(['AOV', snapshot.aov.toStringAsFixed(2)]);
    header([
      'Completion rate',
      '${(snapshot.completionRate * 100).toStringAsFixed(2)}%'
    ]);
    header([
      'Cancellation rate',
      '${(snapshot.cancellationRate * 100).toStringAsFixed(2)}%'
    ]);
    header([
      'Average delivery minutes',
      snapshot.avgDeliveryMinutes.toStringAsFixed(1)
    ]);
    header(
        ['Repeat rate', '${(snapshot.repeatRate * 100).toStringAsFixed(2)}%']);
    header(['Repeat consumers', snapshot.repeatConsumers]);
    header(['Delivered consumers', snapshot.uniqueConsumers]);

    section('Daily trend');
    header(['Date', 'Orders', 'GMV']);
    for (final point in snapshot.dailyTrend) {
      header([
        _date(point.date),
        point.orders,
        point.gmv.toStringAsFixed(2),
      ]);
    }

    section('Status breakdown');
    header(['Status', 'Orders']);
    for (final item in snapshot.statusBreakdown) {
      header([item.status, item.count]);
    }

    section('Top vendors by GMV');
    header(['Vendor', 'District', 'Orders', 'Delivered', 'GMV', 'Fill rate']);
    for (final vendor in snapshot.topVendors) {
      header([
        vendor.name,
        vendor.district,
        vendor.orders,
        vendor.delivered,
        vendor.gmv.toStringAsFixed(2),
        '${(vendor.fillRate * 100).toStringAsFixed(1)}%',
      ]);
    }

    section('Demand by brand');
    header(['Brand', 'Orders']);
    for (final item in snapshot.brandDemand) {
      header([item.label, item.count]);
    }

    section('Demand by size');
    header(['Size', 'Orders']);
    for (final item in snapshot.sizeDemand) {
      header([item.label, item.count]);
    }

    section('District performance');
    header(['District', 'Orders', 'Delivered', 'GMV']);
    for (final item in snapshot.districtPerformance) {
      header([
        item.district,
        item.orders,
        item.delivered,
        item.gmv.toStringAsFixed(2),
      ]);
    }

    section('Vendor scorecards');
    header([
      'Vendor',
      'District',
      'Orders',
      'Delivered',
      'Cancelled',
      'GMV',
      'Fill rate',
      'Avg delivery minutes',
    ]);
    for (final vendor in snapshot.vendorScorecards) {
      header([
        vendor.name,
        vendor.district,
        vendor.orders,
        vendor.delivered,
        vendor.cancelled,
        vendor.gmv.toStringAsFixed(2),
        '${(vendor.fillRate * 100).toStringAsFixed(1)}%',
        vendor.avgDeliveryMinutes.toStringAsFixed(1),
      ]);
    }

    return rows.map((row) => row.map(_cell).join(',')).join('\n');
  }

  static String _date(DateTime value) {
    final day = AnalyticsService.eatDate(value);
    return '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
  }

  static String _cell(Object? value) {
    final text = value?.toString() ?? '';
    if (!text.contains(RegExp(r'[",\n]'))) return text;
    return '"${text.replaceAll('"', '""')}"';
  }
}
