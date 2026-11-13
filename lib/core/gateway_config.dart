// lib/core/gateway_config.dart
// Single source of truth for the self-hosted GasLink SMS & AI gateway.
//
// Values are supplied at build time so secrets never live in source control:
//   flutter build apk --release \
//     --dart-define-from-file=env.local.json
//
// env.local.json (gitignored):
//   {
//     "SMS_GATEWAY_BASE_URL": "http://192.168.1.12:8080",
//     "SMS_GATEWAY_API_KEY": "gl-...",
//     "ENABLE_OTP_LOGIN": "false"
//   }

class GatewayConfig {
  GatewayConfig._();

  /// Local Wi-Fi default. Override with SMS_GATEWAY_BASE_URL to use a tunnel.
  static const String baseUrl = String.fromEnvironment(
    'SMS_GATEWAY_BASE_URL',
    defaultValue: 'http://192.168.1.12:8080',
  );

  /// Tenant key sent as the `x-api-key` header. Empty disables SMS safely.
  static const String apiKey = String.fromEnvironment('SMS_GATEWAY_API_KEY');

  /// OTP login is a foundation only until the auth hardening phase.
  static const bool enableOtpLogin = bool.fromEnvironment(
    'ENABLE_OTP_LOGIN',
    defaultValue: false,
  );

  static const Duration requestTimeout = Duration(seconds: 15);

  static bool get hasApiKey => apiKey.trim().isNotEmpty;

  static Uri endpoint(String path) {
    final cleanBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanBase$cleanPath');
  }
}
