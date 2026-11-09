/// Shared FIFO depletion model for gas cylinders.
///
/// The Cylinder Smart Hub and the consumer home card must always agree on how
/// much gas is left. Both now use [calculateFifo].
///
/// Rules:
/// - Deliveries are consumed oldest first (FIFO): one cylinder is depleted
///   completely before the next one starts.
/// - Each cylinder has its own cycle (30 days by default).
/// - [FifoCollective.totalPercentage] is the SUM of the per-cylinder
///   percentages, so two full cylinders read 200%, not 100%.
/// - [FifoCollective.capacityFraction] is the fraction of total capacity still
///   remaining (59 / 60 = 0.9833), which is what a progress bar should show.
library;

class FifoUnit {
  const FifoUnit({
    required this.deliveredAt,
    required this.cycleDays,
    required this.remainingDays,
    required this.percentage,
  });

  final DateTime deliveredAt;
  final int cycleDays;
  final int remainingDays;

  /// Remaining share of this unit's own cycle, 0..100.
  final double percentage;

  bool get isEmpty => remainingDays <= 0;
}

class FifoCollective {
  const FifoCollective({
    required this.units,
    required this.totalRemainingDays,
    required this.totalPercentage,
    required this.totalCapacityDays,
  });

  final List<FifoUnit> units;

  /// Sum of the remaining days of every cylinder in the group.
  final int totalRemainingDays;

  /// Sum of the per-cylinder percentages. Can exceed 100%.
  final double totalPercentage;

  /// Sum of the cycle days of every cylinder in the group.
  final int totalCapacityDays;

  int get count => units.length;

  bool get isEmpty => totalRemainingDays <= 0;

  /// 0.0..1.0 fraction of total capacity still remaining.
  ///
  /// For two full 30-day cylinders this is 1.0 (100%), and after one day it is
  /// 59 / 60 = 0.9833 — even though [totalPercentage] reads 196.67%.
  double get capacityFraction {
    if (totalCapacityDays <= 0) return 0.0;
    return (totalRemainingDays / totalCapacityDays).clamp(0.0, 1.0).toDouble();
  }
}

/// Calculates FIFO depletion for a set of delivery dates.
///
/// [deliveryDates] do not need to be sorted. [cycleDays] applies to every
/// cylinder in the set (30 in the pilot). [now] exists for tests.
FifoCollective calculateFifo(
  List<DateTime> deliveryDates, {
  int cycleDays = 30,
  DateTime? now,
}) {
  final days = cycleDays > 0 ? cycleDays : 30;
  final dates = List<DateTime>.from(deliveryDates)
    ..sort((a, b) => a.compareTo(b));

  if (dates.isEmpty) {
    return const FifoCollective(
      units: [],
      totalRemainingDays: 0,
      totalPercentage: 0.0,
      totalCapacityDays: 0,
    );
  }

  final today = now ?? DateTime.now();
  int daysToConsume = today.difference(dates.first).inDays;
  if (daysToConsume < 0) daysToConsume = 0;

  final units = <FifoUnit>[];
  int totalRemainingDays = 0;
  double totalPercentage = 0.0;

  for (final deliveredAt in dates) {
    final int remainingDays;
    if (daysToConsume >= days) {
      remainingDays = 0;
      daysToConsume -= days;
    } else {
      remainingDays = days - daysToConsume;
      daysToConsume = 0;
    }

    final percentage =
        (remainingDays / days * 100.0).clamp(0.0, 100.0).toDouble();

    totalRemainingDays += remainingDays;
    totalPercentage += percentage;

    units.add(
      FifoUnit(
        deliveredAt: deliveredAt,
        cycleDays: days,
        remainingDays: remainingDays,
        percentage: percentage,
      ),
    );
  }

  return FifoCollective(
    units: units,
    totalRemainingDays: totalRemainingDays,
    totalPercentage: totalPercentage,
    totalCapacityDays: dates.length * days,
  );
}

/// Parses a stored refill cycle such as `30`, `'30'` or `'Every 30 days'`.
/// Returns [fallback] when nothing usable is found.
int parseCycleDays(dynamic raw, {int fallback = 30}) {
  if (raw is num) {
    final value = raw.toInt();
    return value > 0 ? value : fallback;
  }
  final match = RegExp(r'\d+').firstMatch(raw?.toString() ?? '');
  final parsed = match == null ? null : int.tryParse(match.group(0)!);
  return (parsed != null && parsed > 0) ? parsed : fallback;
}
