// lib/services/referral_service.dart
// Referral foundation: deterministic short codes on users/vendors and a
// referrals collection. Rewards are intentionally not implemented yet.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Readable alphabet without ambiguous characters (no 0/O, 1/I/L).
const String referralAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

/// Generates a stable 6-character referral code from a uid.
///
/// Pure and deterministic: the same uid always produces the same code, so a
/// code can be recomputed even if the stored field is missing.
String generateReferralCode(String uid) {
  final seed = uid.trim().isEmpty ? 'gaslink' : uid.trim();
  var hash = 0x811c9dc5; // FNV-1a 32-bit offset basis.
  for (final unit in seed.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }

  final buffer = StringBuffer();
  for (var i = 0; i < 6; i++) {
    buffer.write(referralAlphabet[hash % referralAlphabet.length]);
    hash =
        ((hash ~/ referralAlphabet.length) ^ (hash * 31 + i * 17)) & 0xFFFFFFFF;
    if (hash == 0) hash = 0x9e3779b9 + i;
  }
  return buffer.toString();
}

class ReferralService {
  ReferralService._();

  static final ReferralService instance = ReferralService._();

  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  CollectionReference<Map<String, dynamic>> get _vendors =>
      FirebaseFirestore.instance.collection('vendors');

  CollectionReference<Map<String, dynamic>> get _referrals =>
      FirebaseFirestore.instance.collection('referrals');

  /// Returns the stored code, creating it when missing. Falls back to the
  /// deterministic code if Firestore is unavailable.
  Future<String> ensureCode({
    required String uid,
    required String role,
  }) async {
    if (uid.isEmpty) return '';
    final collection = role == 'vendor' ? _vendors : _users;
    try {
      final doc = await collection.doc(uid).get();
      final existing =
          (doc.data()?['referralCode'] ?? '').toString().trim().toUpperCase();
      if (existing.isNotEmpty) return existing;

      final code = generateReferralCode(uid);
      await collection
          .doc(uid)
          .set({'referralCode': code}, SetOptions(merge: true));
      return code;
    } catch (e) {
      debugPrint('Referral code warning: $e');
      return generateReferralCode(uid);
    }
  }

  /// Consumer -> vendor introduction. Writes an invited referral doc.
  Future<void> inviteVendor({
    required String referrerUid,
    required String shopName,
    required String phone,
  }) async {
    if (referrerUid.isEmpty) {
      throw Exception('Ingia kwanza / Sign in first');
    }
    await _referrals.add({
      'referrerUid': referrerUid,
      'referrerRole': 'consumer',
      'refereeRole': 'vendor',
      'refereeShopName': shopName.trim(),
      'refereePhone': phone.trim(),
      'status': 'invited',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> referralsBy(String uid) {
    return _referrals.where('referrerUid', isEqualTo: uid).snapshots();
  }
}
