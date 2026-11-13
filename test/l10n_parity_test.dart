import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> readArb(String path) {
    return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  }

  Set<String> messageKeys(Map<String, dynamic> arb) {
    return arb.keys.where((key) => !key.startsWith('@')).toSet();
  }

  test('Swahili and English ARB files have the same message keys', () {
    final sw = readArb('lib/l10n/app_sw.arb');
    final en = readArb('lib/l10n/app_en.arb');

    final swKeys = messageKeys(sw);
    final enKeys = messageKeys(en);

    expect(swKeys.difference(enKeys), isEmpty,
        reason: 'Keys missing from app_en.arb');
    expect(enKeys.difference(swKeys), isEmpty,
        reason: 'Keys missing from app_sw.arb');
  });

  test('every ARB message has non-empty Swahili and English text', () {
    final sw = readArb('lib/l10n/app_sw.arb');
    final en = readArb('lib/l10n/app_en.arb');

    for (final key in messageKeys(sw)) {
      expect((sw[key] as String).trim(), isNotEmpty, reason: 'sw.$key');
      expect((en[key] as String).trim(), isNotEmpty, reason: 'en.$key');
    }
  });

  test('every template key is referenced from lib', () {
    final sw = readArb('lib/l10n/app_sw.arb');
    final source = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');

    for (final key in messageKeys(sw)) {
      expect(
        RegExp('\\b${RegExp.escape(key)}\\b').hasMatch(source),
        isTrue,
        reason: 'Unused ARB key: $key',
      );
    }
  });
}
