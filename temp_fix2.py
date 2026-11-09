import os

path = '/Users/apple/gaslink_app/lib/screens/consumer/consumer_home_screen.dart'

with open(path, 'r') as f:
    content = f.read()

# Fix 4: Update the LinearProgressIndicator value
old_progress = '''                              value: estimatedRemainingRatio,
                              backgroundColor: Colors.grey.shade100,
                              color: isCriticalLow ? Colors.red : Colors.orange,'''
new_progress = '''                              value: (estimatedRemainingRatio ?? 0.0).clamp(0.0, 1.0),
                              backgroundColor: Colors.grey.shade100,
                              color: Colors.green.shade700,'''

if old_progress in content:
    content = content.replace(old_progress, new_progress)
    print('Fixed progress indicator')
else:
    print('progress indicator pattern not found')

# Fix 5: Remove isCriticalLow declaration
old_decl = '''                bool isTankEmptyState;
                bool isCriticalLow;'''
new_decl = '''                // isTankEmptyState, isCriticalLow removed - no longer needed for collective display'''
if old_decl in content:
    content = content.replace(old_decl, new_decl)
    print('Removed isTankEmptyState declaration')
else:
    print('isTankEmptyState declaration not found')

# Fix 6: Remove isCriticalLow from progress indicator color
old_color = '''                              color: isCriticalLow ? Colors.red : Colors.orange,'''
new_color = '''                              color: Colors.green.shade700,'''
if old_color in content:
    content = content.replace(old_color, new_color)
    print('Fixed progress color')
else:
    print('progress color pattern not found')

with open(path, 'w') as f:
    f.write(content)
print('File updated')
