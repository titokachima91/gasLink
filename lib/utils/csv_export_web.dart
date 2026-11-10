// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

/// Web export path: triggers a real CSV download.
Future<String> exportCsv({
  required String filename,
  required String csv,
}) async {
  final blob = html.Blob([csv], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return 'CSV downloaded ($filename)';
}
