// lib/core/app_error.dart
// Typed, locale-neutral errors thrown by services.
//
// Screens map [code] to a localized message so services never build UI text.

class AppError implements Exception {
  const AppError(this.code, {this.arg});

  final String code;
  final Object? arg;

  static const String invalidPhone = 'invalid_phone';
  static const String invalidPin = 'invalid_pin';
  static const String accountExists = 'account_exists';
  static const String accountNotFound = 'account_not_found';
  static const String accountLocked = 'account_locked';
  static const String incorrectPin = 'incorrect_pin';
  static const String roleNotConfigured = 'role_not_configured';

  @override
  String toString() => 'AppError($code)';
}
