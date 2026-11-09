//lib/utils/utils.dart
//This utility class provides helper methods for phone number normalization,
//validation, and formatting. GasLink is Tanzania-only for the pilot, so all
//phone numbers are normalized to the +255[67]XXXXXXXX form.
class Utils {
  /// Normalizes a Tanzanian mobile number to `+255XXXXXXXXX`.
  ///
  /// Accepts:
  /// - `0767304776`
  /// - `767304776`
  /// - `255767304776`
  /// - `+255767304776`
  /// - variants with spaces, dashes or brackets.
  static String normalizePhone(String raw) {
    final p = raw.replaceAll(RegExp(r'[\s\-()]'), '').trim();
    if (p.isEmpty) return p;

    final withoutPlus = p.startsWith('+') ? p.substring(1) : p;

    // 0767304776 -> +255767304776
    if (withoutPlus.startsWith('0') && withoutPlus.length == 10) {
      return '+255${withoutPlus.substring(1)}';
    }

    // 767304776 -> +255767304776
    if (withoutPlus.startsWith('7') && withoutPlus.length == 9) {
      return '+255$withoutPlus';
    }

    // 255767304776 -> +255767304776
    if (withoutPlus.startsWith('255') && withoutPlus.length == 12) {
      return '+$withoutPlus';
    }

    // Already normalized (or unrecognizable). Keep a leading + so callers can
    // validate it with [isValidTzPhone].
    return p.startsWith('+') ? p : '+$p';
  }

  /// True when [raw] is a valid Tanzanian mobile number.
  static bool isValidTzPhone(String raw) {
    final p = normalizePhone(raw);
    return RegExp(r'^\+255[67]\d{8}$').hasMatch(p);
  }

  static bool isValidLoginPhone(String raw) {
    return isValidTzPhone(raw);
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
