import os

path = '/Users/apple/gaslink_app/lib/screens/consumer/consumer_home_screen.dart'

with open(path, 'r') as f:
    content = f.read()

# Fix 1: Change itemCount from _myCylinders.length to groups.length
old_item_count = '''              itemCount: _myCylinders.length,'''
new_item_count = '''              itemCount: groups.length,'''
if old_item_count in content:
    content = content.replace(old_item_count, new_item_count)
    print('Fixed itemCount')
else:
    print('itemCount pattern not found')

# Fix 2: Change the itemBuilder variable declarations
old_item_builder = '''              itemBuilder: (context, index) {
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

new_item_builder = '''              itemBuilder: (context, index) {
                final groupCylinders = groups[index].value;
                final brandName = (groupCylinders.first['brand'] ?? 'Gesi').toString();
                final weight = (groupCylinders.first['weight'] ?? '15kg').toString();

                // Aggregate collective from all cylinders in group (FIFO)
                int totalRemainingDays = 0;
                double totalPercentage = 0.0;
                for (var c in groupCylinders) {
                  totalRemainingDays += (c['remainingDays'] ?? 0);
                  totalPercentage += (c['percentage'] ?? 0);
                }
                final estimatedDaysLeft = totalRemainingDays;
                final remainingPercentage = totalPercentage;'''

if old_item_builder in content:
    content = content.replace(old_item_builder, new_item_builder)
    print('Fixed itemBuilder')
else:
    print('itemBuilder pattern not found')

with open(path, 'w') as f:
    f.write(content)
print('File updated')
