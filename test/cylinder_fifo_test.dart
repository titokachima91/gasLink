import 'package:flutter_test/flutter_test.dart';
import 'package:gaslink_app/utils/cylinder_fifo.dart';

void main() {
  group('calculateFifo', () {
    test('two full 30-day cylinders read 200% and a full bar', () {
      final now = DateTime(2026, 11, 8, 12);
      final result = calculateFifo(
        [now, now],
        cycleDays: 30,
        now: now,
      );

      expect(result.totalRemainingDays, 60);
      expect(result.totalPercentage, closeTo(200.0, 0.0001));
      expect(result.totalCapacityDays, 60);
      expect(result.capacityFraction, 1.0);
      expect(result.isEmpty, isFalse);
    });

    test('FIFO after one day: 59 days, 196.7%, bar 98.33%', () {
      final now = DateTime(2026, 11, 8, 12);
      final result = calculateFifo(
        [now.subtract(const Duration(days: 1)), now],
        cycleDays: 30,
        now: now,
      );

      expect(result.totalRemainingDays, 59);
      expect(result.totalPercentage, closeTo(196.666666, 0.0001));
      expect(result.capacityFraction, closeTo(59 / 60, 0.0001));
      expect(result.units.first.remainingDays, 29);
      expect(result.units.last.remainingDays, 30);
    });

    test('two cylinders bought the same day still follow FIFO (29 + 30)', () {
      final now = DateTime(2026, 11, 8, 12);
      final yesterday = now.subtract(const Duration(days: 1));
      final result = calculateFifo(
        [yesterday, yesterday],
        cycleDays: 30,
        now: now,
      );

      // Only the oldest unit is consumed; the second stays untouched.
      expect(result.totalRemainingDays, 59);
      expect(result.totalPercentage, closeTo(196.666666, 0.0001));
      expect(result.capacityFraction, closeTo(59 / 60, 0.0001));
      expect(result.units[0].remainingDays, 29);
      expect(result.units[1].remainingDays, 30);
    });

    test('one full + one empty cylinder reads 100% but a half bar', () {
      final now = DateTime(2026, 11, 8, 12);
      final result = calculateFifo(
        [now.subtract(const Duration(days: 30)), now],
        cycleDays: 30,
        now: now,
      );

      expect(result.totalRemainingDays, 30);
      expect(result.totalPercentage, closeTo(100.0, 0.0001));
      expect(result.capacityFraction, closeTo(0.5, 0.0001));
    });

    test('oldest cylinder depletes completely before the next one', () {
      final now = DateTime(2026, 11, 8, 12);
      final result = calculateFifo(
        [
          now.subtract(const Duration(days: 35)),
          now.subtract(const Duration(days: 5)),
          now,
        ],
        cycleDays: 30,
        now: now,
      );

      // 35 days used the first cylinder (30) and 5 days of the second.
      expect(result.units[0].remainingDays, 0);
      expect(result.units[1].remainingDays, 25);
      expect(result.units[2].remainingDays, 30);
      expect(result.totalRemainingDays, 55);
      expect(result.totalPercentage, closeTo(0 + 83.333333 + 100, 0.001));
      expect(result.capacityFraction, closeTo(55 / 90, 0.0001));
    });

    test('all cylinders empty when total usage exceeds capacity', () {
      final now = DateTime(2026, 11, 8, 12);
      final result = calculateFifo(
        [
          now.subtract(const Duration(days: 100)),
          now.subtract(const Duration(days: 70)),
        ],
        cycleDays: 30,
        now: now,
      );

      expect(result.totalRemainingDays, 0);
      expect(result.totalPercentage, 0.0);
      expect(result.capacityFraction, 0.0);
      expect(result.isEmpty, isTrue);
    });

    test('empty input is safe', () {
      final result = calculateFifo(const [], cycleDays: 30);
      expect(result.units, isEmpty);
      expect(result.totalRemainingDays, 0);
      expect(result.capacityFraction, 0.0);
      expect(result.isEmpty, isTrue);
    });
  });

  group('parseCycleDays', () {
    test('accepts numbers and text', () {
      expect(parseCycleDays(30), 30);
      expect(parseCycleDays('45'), 45);
      expect(parseCycleDays('Every 60 days'), 60);
    });

    test('falls back for missing or invalid values', () {
      expect(parseCycleDays(null), 30);
      expect(parseCycleDays(''), 30);
      expect(parseCycleDays(0), 30);
      expect(parseCycleDays('abc'), 30);
      expect(parseCycleDays(null, fallback: 14), 14);
    });
  });
}
