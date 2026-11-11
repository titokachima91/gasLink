/// Normalizes stored extra-service strings to the canonical list.
///
/// Older builds saved fuzzy or duplicated variants. This maps every stored
/// entry to exactly one standard service and dedupes, so counters reflect the
/// number of genuinely ticked services. The mandatory weighing consent is not
/// a service and is handled separately by its own field.
List<String> normalizeOfferedServices(
  List<String> stored,
  List<String> standard,
) {
  final result = <String>[];
  for (final entry in stored) {
    final trimmed = entry.trim();
    if (trimmed.isEmpty) continue;
    final match = _match(trimmed, standard);
    if (match != null && !result.contains(match)) {
      result.add(match);
    }
  }
  return result;
}

String? _match(String entry, List<String> standard) {
  final entryLower = entry.toLowerCase();
  // Entries shorter than this are legacy fragments too ambiguous to trust.
  if (entryLower.length < 6) return null;
  for (final candidate in standard) {
    final swahiliPart = candidate.split('/').first.trim().toLowerCase();
    final full = candidate.toLowerCase();
    if (entryLower == full ||
        entryLower == swahiliPart ||
        entryLower.contains(swahiliPart) ||
        full.contains(entryLower)) {
      return candidate;
    }
  }
  return null;
}
