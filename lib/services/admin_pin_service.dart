import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for persisting small pieces of app state across
/// restarts via [SharedPreferences]:
///
/// - the admin PIN, and
/// - the signed-in session (role / phone / user id) so a user stays logged in
///   until they explicitly log out or a different account logs in.
///
/// The PIN is stored as a plain string; for production you may want to encrypt
/// it before persisting.
class AdminPinService {
  static const _pinKey = 'admin_pin';
  static const _sessionRoleKey = 'session_role';
  static const _sessionPhoneKey = 'session_phone';
  static const _sessionUserIdKey = 'session_user_id';

  // Keys used by an earlier build. Read once and migrated so existing users
  // are not logged out after upgrading.
  static const _legacyRoleKey = 'gaslink_session_role';
  static const _legacyPhoneKey = 'gaslink_session_phone';
  static const _legacyUserIdKey = 'gaslink_session_uid';

  static final AdminPinService instance = AdminPinService._internal();
  AdminPinService._internal();

  // --- Admin PIN ------------------------------------------------------------

  /// Saves the admin PIN.
  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
  }

  /// Retrieves the admin PIN, or null if not set.
  Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey);
  }

  /// Clears the stored PIN (e.g., on logout).
  Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
  }

  // --- Session persistence --------------------------------------------------

  /// Persists the active session. Called on login / register / guest login, so
  /// a new account simply overwrites the previous one.
  Future<void> saveSession({
    required String role,
    String? phone,
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionRoleKey, role);
    await _writeOrRemove(prefs, _sessionPhoneKey, phone);
    await _writeOrRemove(prefs, _sessionUserIdKey, userId);
    // Drop legacy keys so an old session cannot come back later.
    await prefs.remove(_legacyRoleKey);
    await prefs.remove(_legacyPhoneKey);
    await prefs.remove(_legacyUserIdKey);
  }

  /// Loads a previously persisted session, or null if nobody is signed in.
  Future<({String role, String? phone, String? userId})?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    var role = prefs.getString(_sessionRoleKey);
    var phone = prefs.getString(_sessionPhoneKey);
    var userId = prefs.getString(_sessionUserIdKey);

    // One-time migration from the earlier key names.
    if (role == null || role.isEmpty) {
      role = prefs.getString(_legacyRoleKey);
      phone = prefs.getString(_legacyPhoneKey);
      userId = prefs.getString(_legacyUserIdKey);
      if (role != null && role.isNotEmpty) {
        await saveSession(role: role, phone: phone, userId: userId);
      }
    }

    if (role == null || role.isEmpty) return null;

    return (
      role: role,
      phone: (phone == null || phone.isEmpty) ? null : phone,
      userId: (userId == null || userId.isEmpty) ? null : userId,
    );
  }

  /// Removes the persisted session. Called on explicit logout.
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionRoleKey);
    await prefs.remove(_sessionPhoneKey);
    await prefs.remove(_sessionUserIdKey);
    await prefs.remove(_legacyRoleKey);
    await prefs.remove(_legacyPhoneKey);
    await prefs.remove(_legacyUserIdKey);
  }

  Future<void> _writeOrRemove(
      SharedPreferences prefs, String key, String? value) async {
    if (value == null || value.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
  }
}
