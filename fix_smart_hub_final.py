with open('lib/screens/consumer/consumer_cylinder_screen.dart', 'r') as f:
    content = f.read()

start_marker = """                      // Collective = sum of real remaining days (true FIFO result)
                      final int collectiveDays = units.fold<int>(
                          0,
                          (sum, u) =>
                              sum +
                              ((u['remainingDays'] as num?)?.toInt() ?? 0));
                      final double collectivePercentage = units.isEmpty
                          ? 0.0
                          : units.fold<double>(
                              0,
                              (sum, u) =>
                                  sum +
                                  ((u['percentage'] as num?)?.toDouble() ?? 0));"""

start_idx = content.find(start_marker)
if start_idx == -1:
    print("Could not find start")
    exit(1)

end_marker = """                      final bool isCollectiveCritical =
                          collectiveRatio <= 0.15 || isCollectiveEmpty;"""

end_idx = content.find(end_marker, start_idx)
if end_idx == -1:
    print("Could not find end")
    exit(1)
end_idx += len(end_marker)

print(f"Replacing from {start_idx} to {end_idx}")

new_code = """                      // ===== COLLECTIVE REAL-TIME CALCULATION (FIFO units) =====
                      // Sum all units' real-time remaining days / total capacity
                      int totalRemainingDays = 0;
                      int totalCycleDays = 0;
                      final int cycleDays = 30; // Default cycle

                      for (final u in units) {
                        final String? uRawDate = u['lastRefillDate'] as String?;
                        final uCycleDays = cycleDays;
                        totalCycleDays += uCycleDays;

                        if (uRawDate != null && uRawDate.isNotEmpty) {
                          final uBaseDate = DateTime.tryParse(uRawDate) ?? DateTime.now();
                          final uDaysElapsed = DateTime.now().difference(uBaseDate).inDays;
                          final uRemaining = uCycleDays - uDaysElapsed;
                          totalRemainingDays += uRemaining.clamp(0, uCycleDays);
                        } else {
                          totalRemainingDays += uCycleDays;
                        }
                      }

                      final double collectiveRatio =
                          units.isNotEmpty
                              ? (totalRemainingDays / totalCycleDays).clamp(0.0, 1.0)
                              : 1.0;
                      final int collectivePercentage = (collectiveRatio * 100).toInt();
                      final int collectiveDaysLeft =
                          units.isNotEmpty ? (totalRemainingDays ~/ units.length) : cycleDays;
                      final bool isCollectiveEmpty = collectiveRatio <= 0.0;
                      final bool isCollectiveCritical = collectiveRatio <= 0.15 || isCollectiveEmpty;"""

new_content = content[:start_idx] + new_code + content[end_idx:]

with open('lib/screens/consumer/consumer_cylinder_screen.dart', 'w') as f:
    f.write(new_content)

print("Smart Hub collective gauge fix applied successfully!")