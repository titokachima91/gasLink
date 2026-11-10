/// Reporting value objects for the admin analytics tab.
///
/// All money is TZS and all calendar bucketing uses Africa/Dar_es_Salaam
/// (UTC+3, no daylight saving).
class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.days,
    required this.from,
    required this.to,
    required this.totalOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.gmv,
    required this.aov,
    required this.completionRate,
    required this.cancellationRate,
    required this.avgDeliveryMinutes,
    required this.repeatRate,
    required this.repeatConsumers,
    required this.uniqueConsumers,
    required this.dailyTrend,
    required this.statusBreakdown,
    required this.topVendors,
    required this.brandDemand,
    required this.sizeDemand,
    required this.districtPerformance,
    required this.vendorScorecards,
  });

  static const String currency = 'TZS';
  static const String timezone = 'Africa/Dar_es_Salaam';

  final int days;
  final DateTime from;
  final DateTime to;
  final int totalOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final double gmv;
  final double aov;
  final double completionRate;
  final double cancellationRate;
  final double avgDeliveryMinutes;
  final double repeatRate;
  final int repeatConsumers;
  final int uniqueConsumers;
  final List<DailyOrderPoint> dailyTrend;
  final List<StatusCount> statusBreakdown;
  final List<VendorPerformance> topVendors;
  final List<DemandCount> brandDemand;
  final List<DemandCount> sizeDemand;
  final List<DistrictPerformance> districtPerformance;
  final List<VendorPerformance> vendorScorecards;

  bool get isEmpty => totalOrders == 0;
}

class DailyOrderPoint {
  const DailyOrderPoint({
    required this.date,
    required this.orders,
    required this.gmv,
  });

  final DateTime date;
  final int orders;
  final double gmv;
}

class StatusCount {
  const StatusCount({required this.status, required this.count});
  final String status;
  final int count;
}

class DemandCount {
  const DemandCount({required this.label, required this.count});
  final String label;
  final int count;
}

class DistrictPerformance {
  const DistrictPerformance({
    required this.district,
    required this.orders,
    required this.delivered,
    required this.gmv,
  });

  final String district;
  final int orders;
  final int delivered;
  final double gmv;
}

class VendorPerformance {
  const VendorPerformance({
    required this.vendorId,
    required this.name,
    required this.district,
    required this.orders,
    required this.delivered,
    required this.cancelled,
    required this.gmv,
    required this.fillRate,
    required this.avgDeliveryMinutes,
  });

  final String vendorId;
  final String name;
  final String district;
  final int orders;
  final int delivered;
  final int cancelled;
  final double gmv;
  final double fillRate;
  final double avgDeliveryMinutes;
}
