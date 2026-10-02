class Utils {
  static String normalizePhone(String raw) {
    final p = raw.replaceAll(RegExp(r'[\s\-()]'), '');
    return p;
  }

  static bool isValidTzPhone(String raw) {
    final p = normalizePhone(raw);
    return RegExp(r'^\+255[67]\d{8}$').hasMatch(p);
  }

  static bool isValidLoginPhone(String raw) {
    final p = normalizePhone(raw);
    return p.startsWith('+') && RegExp(r'^\+\d{8,15}$').hasMatch(p);
  }

  static String formatTzs(num amount) {
    final s = amount.toStringAsFixed(0);
    final withCommas = s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'TZS $withCommas';
  }
}
