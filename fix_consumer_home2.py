with open('lib/screens/consumer/consumer_home_screen.dart', 'r') as f:
    content = f.read()

# Find the old itemBuilder return Column that uses undefined variables
# It starts with "return Column(" after the old calculations
start_marker = """                final int remainingPercentage = collectivePercentage;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$brandName $weight',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87),
                        ),
                        Text(
                          isTankEmptyState
                              ? 'Imeisha / Empty (0%)'
                              : 'Zimebaki ~$estimatedDaysLeft Siku ($remainingPercentage%)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCriticalLow
                                ? Colors.red
                                : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: estimatedRemainingRatio,
                              backgroundColor: Colors.grey.shade100,
                              color: isCriticalLow ? Colors.red : Colors.orange,
                              minHeight: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );"""

start_idx = content.find(start_marker)
if start_idx == -1:
    print("Could not find start marker")
    # Try partial
    partial = "isTankEmptyState"
    start_idx = content.find(partial)
    if start_idx != -1:
        # Find the beginning of the return Column
        start_idx = content.rfind("return Column(", 0, start_idx)
        print(f"Found partial at {start_idx}")

end_marker = """                );
              },
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),"""

end_idx = content.find(end_marker, start_idx)
if end_idx != -1:
    end_idx += len(end_marker)
    print(f"Found end at {end_idx}")
else:
    print("Could not find end marker")

if start_idx >= 0 and end_idx > start_idx:
    print(f"Replacing from {start_idx} to {end_idx}")
    
    new_code = """                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$brandName $weight',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87),
                        ),
                        Text(
                          isEmpty
                              ? 'Imeisha / Empty (0%)'
                              : 'Zimebaki ~$remainingDays Siku ($percentage%)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCritical ? Colors.red : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              backgroundColor: Colors.grey.shade100,
                              color: isCritical ? Colors.red : Colors.orange,
                              minHeight: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),"""

    new_content = content[:start_idx] + new_code + content[end_idx:]
    
    with open('lib/screens/consumer/consumer_home_screen.dart', 'w') as f:
        f.write(new_content)
    print("Replacement done!")
else:
    print("Failed to find markers")