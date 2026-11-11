// lib/services/auth_service.dart
// This service handles user authentication and session management, providing registration,
// login, logout, and role retrieval. It interacts with Firebase Firestore to manage user details,
// hashed PIN credentials, and account lockouts. Upon successful authentication, it explicitly
// triggers the notification service to link the active device FCM token to the user document.

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'admin_pin_service.dart';
import 'notification_service.dart';
import '../utils/utils.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // --- Web Push VAPID Key ---
  // Replace this placeholder string with your Web Push Key Pair from Firebase Console:
  // Firebase Console -> Project Settings -> Cloud Messaging -> Web configuration -> Web Push certificates
  static const String vapidKey =
      'BMmY8PbPwaWnj3mnP9pRrQ2FZWDYlO9hLbR3r9MQBUY87LQ3FDHwkczDXePgQRZG71XslxqI_o0vHK9S0O4IwrE';

  // --- Roles ---
  static const String roleConsumer = 'consumer';
  static const String roleVendor = 'vendor';
  static const String roleAdmin = 'admin';

  /// Roles the app knows how to route. Anything else is treated as corrupt
  /// session data and ignored.
  static const Set<String> validRoles = {roleConsumer, roleVendor, roleAdmin};

  // --- Hardcoded admin access (temporary until the admin panel is built) ---
  static const String adminPhone = '+255767304776';
  static const String adminPin = '0000';

  // --- Session state (in-memory) ---
  String? currentRole;
  String? currentPhone;
  String? currentUserId;

  /// The active session belongs to a visitor browsing without an account.
  bool get isGuest => currentRole == 'guest';

  /// The active session belongs to a registered consumer.
  bool get isRegisteredConsumer => currentRole == roleConsumer;

  bool get isVendor => currentRole == roleVendor;

  bool get isAdmin => currentRole == roleAdmin;

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

    // Clear the persisted session so the app asks for login again.
    try {
      await AdminPinService.instance.clearSession();
    } catch (e) {
      debugPrint(
          'Warning: Could not clear persisted session during logout: $e');
    }
  }

  /// Restores the session saved by a previous login so the user does not have
  /// to log in again after an app restart. Call this once during startup,
  /// before `runApp`.
  Future<void> restoreSession() async {
    try {
      final session = await AdminPinService.instance.loadSession();
      if (session == null) return;

      // Only restore sessions the router can actually use. Corrupt or
      // outdated roles force a clean login instead of a blank screen.
      if (!validRoles.contains(session.role)) {
        debugPrint(
            '⚠️ Ignoring persisted session with unknown role: ${session.role}');
        await AdminPinService.instance.clearSession();
        return;
      }

      currentRole = session.role;
      currentPhone = session.phone;
      currentUserId = session.userId;
      debugPrint('♻️ Restored ${session.role} session from storage.');
    } catch (e) {
      debugPrint('Warning: Could not restore persisted session: $e');
    }
  }

  /// Writes the current in-memory session to persistent storage.
  Future<void> _persistSession() async {
    final role = currentRole;
    if (role == null || role.isEmpty) return;
    try {
      await AdminPinService.instance.saveSession(
        role: role,
        phone: currentPhone,
        userId: currentUserId,
      );
    } catch (e) {
      debugPrint('Warning: Could not persist session: $e');
    }
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
    await _persistSession();
  }

  /// Records consent on the user document. Skipped for the hardcoded admin
  /// identity, which has no user document.
  Future<void> saveConsents({
    required String uid,
    required bool adsConsent,
  }) async {
    if (uid.isEmpty || uid == 'admin_local') return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'termsAcceptedAt': FieldValue.serverTimestamp(),
        'adsConsent': adsConsent,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Consent save warning: $e');
    }
  }

  Future<void> register(String phone, String pin,
      {bool adsConsent = true}) async {
    final cleanPhone = Utils.normalizePhone(phone);
    final cleanPin = pin.trim();

    if (!Utils.isValidTzPhone(cleanPhone)) {
      throw Exception(
          'Namba ya simu si sahihi / Invalid phone number (e.g. 0767304776)');
    }
    if (cleanPin.length != 4 || int.tryParse(cleanPin) == null) {
      throw Exception('PIN lazima iwe namba 4 / PIN must be 4 digits');
    }

    final db = FirebaseFirestore.instance;
    final existing = await db
        .collection('users')
        .where('phone', whereIn: _phoneVariants(phone.trim(), cleanPhone))
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
      'termsAcceptedAt': FieldValue.serverTimestamp(),
      'adsConsent': adsConsent,
      'createdAt': FieldValue.serverTimestamp(),
    });

    currentRole = 'consumer';
    currentPhone = cleanPhone;
    currentUserId = newDoc.id;
    await _persistSession();

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

  /// Every representation the same TZ number may have been stored under before
  /// normalization was enforced.
  List<String> _phoneVariants(String rawPhone, String cleanPhone) {
    final variants = <String>{rawPhone.trim(), cleanPhone};
    final digits = cleanPhone.replaceFirst('+', '');
    if (digits.startsWith('255') && digits.length == 12) {
      final local = digits.substring(3);
      variants.add(digits);
      variants.add('0$local');
      variants.add(local);
    }
    variants.removeWhere((value) => value.isEmpty);
    return variants.take(10).toList();
  }

  /// Hardcoded admin access. No Firestore account is needed while the admin
  /// panel is still a stub.
  Future<Map<String, dynamic>?> adminLogin(String phone, String pin) async {
    final cleanPhone = Utils.normalizePhone(phone);
    final cleanPin = pin.trim();

    if (cleanPhone != adminPhone) return null;
    if (cleanPin != adminPin) {
      throw Exception('PIN si sahihi / Incorrect PIN');
    }

    currentRole = roleAdmin;
    currentPhone = cleanPhone;
    currentUserId = 'admin_local';
    await _persistSession();
    debugPrint('👑 Admin login successful for $cleanPhone');
    return {'role': roleAdmin, 'phone': cleanPhone, 'uid': 'admin_local'};
  }

  Future<Map<String, dynamic>?> login(String phone, String pin) async {
    final rawPhone = phone.trim();
    final cleanPin = pin.trim();
    final cleanPhone = Utils.normalizePhone(rawPhone);

    // A new login attempt must never inherit a stale in-memory session.
    currentRole = null;
    currentPhone = null;
    currentUserId = null;

    if (!Utils.isValidTzPhone(cleanPhone)) {
      throw Exception(
          'Namba ya simu si sahihi / Invalid phone number (e.g. 0767304776)');
    }
    if (cleanPin.length != 4 || int.tryParse(cleanPin) == null) {
      throw Exception('PIN lazima iwe namba 4 / PIN must be 4 digits');
    }

    // 1. Hardcoded admin is checked before touching Firestore.
    if (cleanPhone == adminPhone) {
      return adminLogin(cleanPhone, cleanPin);
    }

    // 2. Registered users. Search every historical representation of the same
    // number so accounts created before normalization still log in.
    final db = FirebaseFirestore.instance;
    final variants = _phoneVariants(rawPhone, cleanPhone);
    final doc = await db
        .collection('users')
        .where('phone', whereIn: variants)
        .limit(1)
        .get();

    debugPrint(
        '🔐 Login query phone=$cleanPhone variants=$variants matches=${doc.docs.length}');

    if (doc.docs.isEmpty) {
      throw Exception('Account haijatambuliwa / Account not found');
    }

    final data = doc.docs.first.data();
    final ref = doc.docs.first.reference;
    final storedPhone = (data['phone'] ?? cleanPhone).toString();

    final lockedUntil = data['lockedUntil'] as Timestamp?;
    if (lockedUntil != null && lockedUntil.toDate().isAfter(DateTime.now())) {
      throw Exception(
          'Akaunti imefungwa kwa dakika 15 / Account locked for 15 minutes');
    }

    if (data['passcodeHash'] != _hash(cleanPin, storedPhone)) {
      final attempts = ((data['pinAttempts'] ?? 0) as num).toInt() + 1;
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

    final role = data['role'] as String?;
    if (role == null || !validRoles.contains(role)) {
      throw Exception(
          'Akaunti haina wadhifa sahihi / Account role is not configured');
    }

    final updates = <String, dynamic>{'pinAttempts': 0, 'lockedUntil': null};
    if (storedPhone != cleanPhone) {
      // Successful login is the safe moment to migrate the canonical phone
      // and re-hash the PIN with it.
      updates['phone'] = cleanPhone;
      updates['passcodeHash'] = _hash(cleanPin, cleanPhone);
    }
    await ref.update(updates);

    currentRole = role;
    currentPhone = cleanPhone;
    currentUserId = doc.docs.first.id;
    await _persistSession();

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

  /// Admin-only: promote an existing user to vendor role.
  /// Call this after you (admin) have created the vendor's /vendors/{uid} profile.
  Future<void> setVendorRole(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'role': roleVendor,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Sync in-memory session if this is the currently logged-in user
      if (currentUserId == uid) {
        currentRole = roleVendor;
      }
    } catch (e) {
      debugPrint('Error setting vendor role for $uid: $e');
      rethrow;
    }
  }

  /// One-time: create a user with a hashed PIN. Use in debug only.
  ///
  /// Existing accounts are left untouched so a restart never resets a PIN
  /// the user may have set.
  Future<void> seedUser(String phone, String pin, String role) async {
    try {
      final db = FirebaseFirestore.instance;
      final cleanPhone = Utils.normalizePhone(phone);
      final cleanPin = pin.trim();

      if (!Utils.isValidTzPhone(cleanPhone) || !validRoles.contains(role)) {
        debugPrint('Skipping seed for invalid phone/role: $phone / $role');
        return;
      }

      final existing = await db
          .collection('users')
          .where('phone', isEqualTo: cleanPhone)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return;

      await db.collection('users').add({
        'phone': cleanPhone,
        'passcodeHash': _hash(cleanPin, cleanPhone),
        'role': role,
        'pinAttempts': 0,
        'lockedUntil': null,
        'mustChangePin': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error seeding test user ($phone): $e');
    }
  }
}
