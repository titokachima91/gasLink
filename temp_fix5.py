import os

path = '/Users/apple/gaslink_app/lib/screens/consumer/consumer_home_screen.dart'

with open(path, 'r') as f:
    content = f.read()

# Fix: Keep the if statement but add grouping logic in the else block
# Find the pattern: if (!hasCylinders) ... ] else ...[
old_pattern = '''          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _myCylinders.length,
              separatorBuilder: (context, index) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(height: 1),
              ),
              itemBuilder: (context, index) {
                final cylinder = _myCylinders[index];
                final brandName = (cylinder['brand'] ?? 'Gesi').toString();
                final weight = (cylinder['weight'] ?? '15kg').toString();
                final cycleStr = (cylinder['refillCycle'] ?? '30').toString();
                final String? rawDate = cylinder['lastRefillDate'] as String?;
                // Prefer stacked values from database when they exist
                final int? storedDays =
                    (cylinder['remainingDays'] as num?)?.toInt();
                final double? storedPercentage =
                    (cylinder['percentage'] as num?)?.toDouble();

                double estimatedRemainingRatio;
                int estimatedDaysLeft;
                bool isTankEmptyState;
                bool isCriticalLow;

                if (storedDays != null && storedPercentage != null) {
                  // Use the stacked values written by finalizeAndRegisterCylinder
                  estimatedDaysLeft = storedDays;
                  estimatedRemainingRatio =
                      (storedPercentage / 100.0).clamp(0.0, 4.0); // allow >100%
                  isTankEmptyState = estimatedDaysLeft <= 0;
                  isCriticalLow =
                      estimatedRemainingRatio <= 0.15 || isTankEmptyState;
                } else {
                  // Fallback: calculate from lastRefillDate + cycle (old behaviour)
                  final cycleStr = (cylinder['refillCycle'] ?? '30').toString();
                  final String? rawDate = cylinder['lastRefillDate'] as String?;
                  DateTime baseDate = DateTime.now();
                  if (rawDate != null && rawDate.isNotEmpty) {
                    baseDate = DateTime.tryParse(rawDate) ?? DateTime.now();
                  }
                  final daysElapsed =
                      DateTime.now().difference(baseDate).inDays;
                  int expectedTotalDays = 30;
                  final Match? match = RegExp(r'\d+').firstMatch(cycleStr);
                  if (match != null) {
                    expectedTotalDays =
                        int.tryParse(match.group(0) ?? '30') ?? 30;
                  }
                  estimatedDaysLeft = expectedTotalDays - daysElapsed;
                  isTankEmptyState = estimatedDaysLeft <= 0;
                  estimatedRemainingRatio =
                      (estimatedDaysLeft / expectedTotalDays).clamp(0.0, 1.0);
                  isCriticalLow =
                      estimatedRemainingRatio <= 0.15 || isTankEmptyState;
                }

                final int remainingPercentage =
                    (estimatedRemainingRatio * 100).toInt();'''

new_code = '''          ] else ...[
            // Group cylinders by brand and weight (FIFO collective display)
            final groups = <String, List<Map<String, dynamic>>>{};
            for (var c in _myCylinders) {
              final key = '${c['brand'] ?? 'Gesi'}-${c['weight'] ?? '15kg'}';
              if (!groups.containsKey(key)) {
                groups[key] = [];
              }
              groups[key]!.add(c);
            }
            final List<Map<String, dynamic>> groupList =
                groups.values.toList().cast<Map<String, dynamic>>();

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groupList.length,
              separatorBuilder: (context, index) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(height: 1),
              ),
              itemBuilder: (context, index) {
                final groupCylinders = groupList[index];
                final String brandName = (groupCylinders.first['brand'] ?? 'Gesi').toString();
                final String weight = (groupCylinders.first['weight'] ?? '15kg').toString();
                final int cylinderCount = groupCylinders.length;

                // Aggregate collective from all cylinders in group (FIFO)
                int totalRemainingDays = 0;
                double totalPercentage = 0.0;
                for (var c in groupCylinders) {
                  totalRemainingDays += (c['remainingDays'] ?? 0);
                  totalPercentage += (c['percentage'] ?? 0);
                }
                final estimatedDaysLeft = totalRemainingDays;
                final remainingPercentage = totalPercentage;
                // For progress indicator - show as fraction (percentage / 100)
                double estimatedRemainingRatio = totalPercentage / 100.0;'''

if old_pattern in content:
    content = content.replace(old_pattern, new_code)
    print('Fixed grouping logic')
else:
    print('grouping pattern not found')

with open(path, 'w') as f:
    f.write(content)
print('File updated')
