import os

path = '/Users/apple/gaslink_app/lib/screens/consumer/consumer_home_screen.dart'

with open(path, 'r') as f:
    content = f.read()

# Fix: Define estimatedRemainingRatio based on totalPercentage (collective)
old_code = '''              // Aggregate collective from all cylinders in group (FIFO)
                int totalRemainingDays = 0;
                double totalPercentage = 0.0;
                for (var c in groupCylinders) {
                  totalRemainingDays += (c['remainingDays'] ?? 0);
                  totalPercentage += (c['percentage'] ?? 0);
                }
                final estimatedDaysLeft = totalRemainingDays;
                final remainingPercentage = totalPercentage;'''

new_code = '''              // Aggregate collective from all cylinders in group (FIFO)
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

if old_code in content:
    content = content.replace(old_code, new_code)
    print('Fixed estimatedRemainingRatio definition')
else:
    print('estimatedRemainingRatio pattern not found')

with open(path, 'w') as f:
    f.write(content)
print('File updated')
