import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  // --- Session state (in-memory) ---
  String? currentRole;
  String? currentPhone;

  Future<void> signOut() async {
    currentRole = null;
    currentPhone = null;
  }

  String _hash(String pin, String phone) =>
      sha256.convert(utf8.encode('pin:pin:pin:phone')).toString();

  Future<Map<String, dynamic>?> login(String phone, String pin) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    if (doc.docs.isEmpty) {
      throw Exception('Account haijatambuliwa / Account not found');
    }
    final data = doc.docs.first.data();
    final ref = doc.docs.first.reference;

    // Lockout check
    final lockedUntil = data['lockedUntil'] as Timestamp?;
    if (lockedUntil != null && lockedUntil.toDate().isAfter(DateTime.now())) {
      throw Exception(
          'Akaunti imefungwa kwa dakika 15 / Account locked for 15 minutes');
    }

    if (data['passcodeHash'] != _hash(pin, phone)) {
      final attempts = ((data['pinAttempts'] ?? 0) as int) + 1;
      if (attempts >= 5) {
        await ref.update({
          'pinAttempts': 0,
          'lockedUntil': Timestamp.fromDate(
              DateTime.now().add(const Duration(minutes: 15))),
        });
        throw Exception(
            'Akaunti imefungwa kwa dakika 15 / Account locked for 15 minutes');
      }
      await ref.update({'pinAttempts': attempts});
      throw Exception('PIN si sahihi / Incorrect PIN');
    }

    await ref.update({'pinAttempts': 0, 'lockedUntil': null});
    currentRole = data['role'] as String?;
    currentPhone = phone;
    return data; // caller reads data['role'] to route
  }

  /// One-time: create/repair a user with a hashed PIN. Use in debug only.
  Future<void> seedUser(String phone, String pin, String role) async {
    final db = FirebaseFirestore.instance;
    final existing = await db
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    final payload = {
      'phone': phone,
      'passcodeHash': _hash(pin, phone),
      'role': role,
      'pinAttempts': 0,
      'lockedUntil': null,
      'mustChangePin': false,
    };
    if (existing.docs.isEmpty) {
      await db.collection('users').add(payload);
    } else {
      await existing.docs.first.reference.update(payload);
    }
  }
}
