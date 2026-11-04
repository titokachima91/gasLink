// lib/services/auth_service.dart
// This service handles user authentication and session management, providing registration,
// login, logout, and role retrieval. It interacts with Firebase Firestore to manage user details,
// hashed PIN credentials, and account lockouts. Upon successful authentication, it explicitly
// triggers the notification service to link the active device FCM token to the user document.

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // --- Web Push VAPID Key ---
  // Replace this placeholder string with your Web Push Key Pair from Firebase Console:
  // Firebase Console -> Project Settings -> Cloud Messaging -> Web configuration -> Web Push certificates
  static const String vapidKey =
      'BMmY8PbPwaWnj3mnP9pRrQ2FZWDYlO9hLbR3r9MQBUY87LQ3FDHwkczDXePgQRZG71XslxqI_o0vHK9S0O4IwrE';

  // --- Session state (in-memory) ---
  String? currentRole;
  String? currentPhone;
  String? currentUserId;

  Future<void> signOut() async {
    // FIXED: Safely wipe the FCM token from the database BEFORE clearing local session variables
    if (currentUserId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({
          'fcmToken': FieldValue
              .delete(), // Completely removes the field from the document
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint(
            '🔒 FCM Token removed successfully from Firestore during logout.');
      } catch (e) {
        debugPrint(
            'Warning: Could not clear FCM token from Firestore during logout: $e');
      }
    }

    // Clear local memory states as usual
    currentRole = null;
    currentPhone = null;
    currentUserId = null;
  }

  Future<String?> getUserRole(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
    } catch (e) {
      debugPrint('Error getting user role: $e');
    }
    return null;
  }

  Future<void> loginAsGuest() async {
    currentRole = 'guest';
    currentPhone = null;
    currentUserId = null;
  }

  Future<void> register(String phone, String pin) async {
    final cleanPhone = phone.trim();
    final cleanPin = pin.trim();

    if (cleanPhone.length < 9) {
      throw Exception('Namba ya simu si sahihi / Invalid phone number');
    }
    if (cleanPin.length != 4 || int.tryParse(cleanPin) == null) {
      throw Exception('PIN lazima iwe namba 4 / PIN must be 4 digits');
    }

    final db = FirebaseFirestore.instance;
    final existing = await db
        .collection('users')
        .where('phone', isEqualTo: cleanPhone)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Akaunti ipo tayari / Account already exists');
    }

    final newDoc = await db.collection('users').add({
      'phone': cleanPhone,
      'role': 'consumer',
      'passcodeHash': _hash(cleanPin, cleanPhone),
      'pinAttempts': 0,
      'lockedUntil': null,
      'mustChangePin': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    currentRole = 'consumer';
    currentPhone = cleanPhone;
    currentUserId = newDoc.id;

    // FIXED: Now passes both the explicit user ID and the VAPID key safely
    try {
      await NotificationService.instance.saveTokenToFirestore(
        uid: newDoc.id,
        vapidKey: vapidKey,
      );
    } catch (e) {
      debugPrint('FCM token save warning during register: $e');
    }
  }

  // FIXED: Hash now correctly encodes actual pin and phone values
  String _hash(String pin, String phone) =>
      sha256.convert(utf8.encode('$pin:$phone')).toString();

  Future<Map<String, dynamic>?> login(String phone, String pin) async {
    final cleanPhone = phone.trim();
    final cleanPin = pin.trim();

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: cleanPhone)
        .limit(1)
        .get();

    if (doc.docs.isEmpty) {
      throw Exception('Account haijatambuliwa / Account not found');
    }

    final data = doc.docs.first.data();
    final ref = doc.docs.first.reference;

    final lockedUntil = data['lockedUntil'] as Timestamp?;
    if (lockedUntil != null && lockedUntil.toDate().isAfter(DateTime.now())) {
      throw Exception(
          'Akaunti imefungwa kwa dakika 15 / Account locked for 15 minutes');
    }

    if (data['passcodeHash'] != _hash(cleanPin, cleanPhone)) {
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
    currentPhone = cleanPhone;
    currentUserId = doc.docs.first.id;

    // FIXED: Now passes both the explicit logged-in user ID and the VAPID key safely
    try {
      await NotificationService.instance.saveTokenToFirestore(
        uid: doc.docs.first.id,
        vapidKey: vapidKey,
      );
    } catch (e) {
      debugPrint('FCM token save warning during login: $e');
    }

    return data;
  }

  /// One-time: create/repair a user with a hashed PIN. Use in debug only.
  Future<void> seedUser(String phone, String pin, String role) async {
    try {
      final db = FirebaseFirestore.instance;
      final cleanPhone = phone.trim();
      final cleanPin = pin.trim();

      final existing = await db
          .collection('users')
          .where('phone', isEqualTo: cleanPhone)
          .limit(1)
          .get();
      final payload = {
        'phone': cleanPhone,
        'passcodeHash': _hash(cleanPin, cleanPhone),
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
    } catch (e) {
      debugPrint('Error seeding test user ($phone): $e');
    }
  }
}
