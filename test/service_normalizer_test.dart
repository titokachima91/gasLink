import 'package:flutter_test/flutter_test.dart';

import 'package:gaslink_app/utils/service_normalizer.dart';

const standard = [
  'Ukaguzi wa Kuvuja kwa Gesi / Gas Leak Inspection',
  'Ufungaji wa Bure Nyumbani / Free Home Installation',
  'Ushauri wa Usalama wa Gesi / Gas Safety Advice',
];

void main() {
  test('keeps canonical entries unchanged', () {
    expect(
      normalizeOfferedServices(
        ['Ukaguzi wa Kuvuja kwa Gesi / Gas Leak Inspection'],
        standard,
      ),
      ['Ukaguzi wa Kuvuja kwa Gesi / Gas Leak Inspection'],
    );
  });

  test('maps legacy Swahili-only variants to the standard string', () {
    expect(
      normalizeOfferedServices(
        ['ukaguzi wa kuvuja kwa gesi', ' Ufungaji wa Bure Nyumbani '],
        standard,
      ),
      [
        'Ukaguzi wa Kuvuja kwa Gesi / Gas Leak Inspection',
        'Ufungaji wa Bure Nyumbani / Free Home Installation',
      ],
    );
  });

  test('dedupes duplicates and trims entries', () {
    expect(
      normalizeOfferedServices(
        [
          'Ukaguzi wa Kuvuja kwa Gesi / Gas Leak Inspection',
          'Ukaguzi wa Kuvuja kwa Gesi / Gas Leak Inspection',
          '',
          '   ',
        ],
        standard,
      ),
      ['Ukaguzi wa Kuvuja kwa Gesi / Gas Leak Inspection'],
    );
  });

  test('drops unknown fragments too short to trust', () {
    expect(
      normalizeOfferedServices(['ges', '??', 'xxxxx'], standard),
      isEmpty,
    );
  });
}
