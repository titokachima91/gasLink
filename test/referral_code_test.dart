import 'package:flutter_test/flutter_test.dart';

import 'package:gaslink_app/services/referral_service.dart';

void main() {
  test('referral code is deterministic and 6 characters', () {
    const uid = 'uid_consumer_123';
    final first = generateReferralCode(uid);
    final second = generateReferralCode(uid);

    expect(first, second);
    expect(first.length, 6);
  });

  test('referral code avoids ambiguous characters', () {
    for (var i = 0; i < 200; i++) {
      final code = generateReferralCode('uid_$i');
      expect(code.length, 6);
      for (final char in code.split('')) {
        expect(referralAlphabet.contains(char), isTrue,
            reason: 'Unexpected character "$char" in $code');
      }
      expect(code.contains('0'), isFalse);
      expect(code.contains('O'), isFalse);
      expect(code.contains('1'), isFalse);
      expect(code.contains('I'), isFalse);
      expect(code.contains('L'), isFalse);
    }
  });

  test('different uids produce different codes', () {
    final codes = {
      for (var i = 0; i < 50; i++) generateReferralCode('consumer_$i'),
    };
    expect(codes.length, greaterThan(45));
  });

  test('empty uid still returns a usable code', () {
    final code = generateReferralCode('');
    expect(code.length, 6);
  });
}
