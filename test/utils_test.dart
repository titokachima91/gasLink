import 'package:flutter_test/flutter_test.dart';
import 'package:gaslink_app/utils/utils.dart';

void main() {
  group('Utils.normalizePhone', () {
    test('accepts every documented Tanzanian format', () {
      expect(Utils.normalizePhone('0767304776'), '+255767304776');
      expect(Utils.normalizePhone('767304776'), '+255767304776');
      expect(Utils.normalizePhone('255767304776'), '+255767304776');
      expect(Utils.normalizePhone('+255767304776'), '+255767304776');
    });

    test('strips spaces, dashes and brackets', () {
      expect(Utils.normalizePhone('0767 304 776'), '+255767304776');
      expect(Utils.normalizePhone('0767-304-776'), '+255767304776');
      expect(Utils.normalizePhone('(0767) 304 776'), '+255767304776');
    });

    test('handles the 06x prefix too', () {
      expect(Utils.normalizePhone('0677304776'), '+255677304776');
    });
  });

  group('Utils.isValidTzPhone', () {
    test('accepts valid TZ mobile numbers', () {
      expect(Utils.isValidTzPhone('0767304776'), isTrue);
      expect(Utils.isValidTzPhone('+255767304776'), isTrue);
      expect(Utils.isValidTzPhone('255677304776'), isTrue);
    });

    test('rejects arbitrary input', () {
      expect(Utils.isValidTzPhone('123456789'), isFalse);
      expect(Utils.isValidTzPhone('0412345678'), isFalse); // landline prefix
      expect(Utils.isValidTzPhone('+25576730477'), isFalse); // too short
      expect(Utils.isValidTzPhone('+2557673047761'), isFalse); // too long
      expect(Utils.isValidTzPhone('hello'), isFalse);
    });
  });
}
