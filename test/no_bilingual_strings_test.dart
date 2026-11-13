import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Files migrated to one-language-at-a-time UI in D1. This list grows with each
/// localization batch until the scan covers all of lib/.
const migratedFiles = <String>[
  'lib/screens/auth/login_screen.dart',
  'lib/screens/auth/register_screen.dart',
  'lib/screens/auth/landing_screen.dart',
  'lib/screens/auth/widgets/auth_widgets.dart',
  'lib/screens/legal/legal_screens.dart',
  'lib/screens/about_screen.dart',
  'lib/core/session_gate.dart',
  'lib/widgets/root_back_guard.dart',
  'lib/widgets/theme_mode_button.dart',
  'lib/widgets/language_picker.dart',
];

void main() {
  test('migrated screens contain no bilingual string literals', () {
    final pattern = RegExp(r'''['"][^'"]*\s/\s[^'"]*['"]''');
    final offenders = <String>[];

    for (final path in migratedFiles) {
      final lines = File(path).readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index].trim();
        if (line.startsWith('//')) continue;
        if (pattern.hasMatch(line)) {
          offenders.add('$path:${index + 1}: $line');
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'Bilingual UI strings found:\n${offenders.join('\n')}');
  });
}
