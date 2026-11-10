/// Small formatting helpers shared by the admin console.
library;

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatNumber(num value) {
  final rounded = value.round();
  final text = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return rounded < 0 ? '-$buffer' : buffer.toString();
}

String formatTzs(num value, {bool compact = false}) {
  if (compact) return 'TZS ${_compact(value)}';
  return 'TZS ${formatNumber(value)}';
}

String _compact(num value) {
  final abs = value.abs();
  if (abs >= 1000000000) {
    return '${(value / 1000000000).toStringAsFixed(1)}B';
  }
  if (abs >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (abs >= 1000) {
    return '${(value / 1000).toStringAsFixed(0)}K';
  }
  return value.round().toString();
}

String formatPercent(double value) => '${(value * 100).toStringAsFixed(1)}%';

String formatDate(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')} '
      '${_months[local.month - 1]} ${local.year}';
}

String formatDateTime(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${formatDate(local)}, $hour:$minute';
}

String formatDurationMinutes(double minutes) {
  if (minutes <= 0) return '—';
  final total = minutes.round();
  if (total < 60) return '${total}m';
  final hours = total ~/ 60;
  final rest = total % 60;
  return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
}

String shortId(String value, {int length = 8}) {
  if (value.length <= length) return value;
  return value.substring(0, length);
}

String initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}
