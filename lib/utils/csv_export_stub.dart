import 'package:flutter/services.dart';

/// Fallback export path for Android, iOS, macOS, Windows and Linux.
///
/// The CSV is copied to the clipboard so admins can paste it into Sheets,
/// Excel or email without adding a file-system dependency to the pilot build.
Future<String> exportCsv({
  required String filename,
  required String csv,
}) async {
  await Clipboard.setData(ClipboardData(text: csv));
  return 'CSV copied to clipboard ($filename)';
}
