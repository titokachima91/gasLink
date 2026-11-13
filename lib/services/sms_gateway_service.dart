// lib/services/sms_gateway_service.dart
// Thin HTTP client for the self-hosted SMS gateway.
//
// Stable contract (x-api-key tenant auth):
//   POST /v1/send-sms    { recipient, message }
//   POST /v1/otp/send    { phone }
//   POST /v1/otp/verify  { phone, ref, code }
//
// The service never throws raw network exceptions into UI code; callers get a
// typed [SmsGatewayException] with a locale-neutral code.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/gateway_config.dart';
import '../utils/utils.dart';

class SmsGatewayException implements Exception {
  const SmsGatewayException(this.code, {this.detail});

  final String code;
  final String? detail;

  static const String notConfigured = 'not_configured';
  static const String invalidPhone = 'invalid_phone';
  static const String network = 'network';
  static const String unauthorized = 'unauthorized';
  static const String rejected = 'rejected';
  static const String invalidResponse = 'invalid_response';

  @override
  String toString() => 'SmsGatewayException($code)';
}

class OtpChallenge {
  const OtpChallenge({required this.ref, this.expiresAt});

  final String ref;
  final DateTime? expiresAt;

  factory OtpChallenge.fromJson(Map<String, dynamic> json) {
    final rawExpiry = json['expiresAt'];
    return OtpChallenge(
      ref: (json['ref'] ?? '').toString(),
      expiresAt: rawExpiry is String ? DateTime.tryParse(rawExpiry) : null,
    );
  }
}

class SmsGatewayService {
  SmsGatewayService({
    http.Client? client,
    String? baseUrl,
    String? apiKey,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? GatewayConfig.baseUrl,
        _apiKey = apiKey ?? GatewayConfig.apiKey,
        _timeout = timeout ?? GatewayConfig.requestTimeout;

  static final SmsGatewayService instance = SmsGatewayService();

  final http.Client _client;
  final String _baseUrl;
  final String _apiKey;
  final Duration _timeout;

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Uri _endpoint(String path) {
    final cleanBase = _baseUrl.replaceAll(RegExp(r'/+$'), '');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanBase$cleanPath');
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey.trim(),
      };

  /// Sends one SMS to a Tanzanian number. Returns normally on success.
  Future<void> sendSms({
    required String recipient,
    required String message,
  }) async {
    final phone = Utils.normalizePhone(recipient);
    if (!Utils.isValidTzPhone(phone)) {
      throw const SmsGatewayException(SmsGatewayException.invalidPhone);
    }
    await _post('/v1/send-sms', {
      'recipient': phone,
      'message': message,
    });
  }

  /// Asks the gateway to create and dispatch an OTP. The code is never returned.
  Future<OtpChallenge> sendOtp(String phone) async {
    final normalized = Utils.normalizePhone(phone);
    if (!Utils.isValidTzPhone(normalized)) {
      throw const SmsGatewayException(SmsGatewayException.invalidPhone);
    }
    final json = await _post('/v1/otp/send', {'phone': normalized});
    final challenge = OtpChallenge.fromJson(json);
    if (challenge.ref.isEmpty) {
      throw const SmsGatewayException(SmsGatewayException.invalidResponse);
    }
    return challenge;
  }

  /// Verifies the code against the reference returned by [sendOtp].
  Future<bool> verifyOtp({
    required String phone,
    required String ref,
    required String code,
  }) async {
    final normalized = Utils.normalizePhone(phone);
    final json = await _post('/v1/otp/verify', {
      'phone': normalized,
      'ref': ref,
      'code': code.trim(),
    });
    return json['verified'] == true;
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    if (!isConfigured) {
      throw const SmsGatewayException(SmsGatewayException.notConfigured);
    }

    http.Response response;
    try {
      response = await _client
          .post(
            _endpoint(path),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const SmsGatewayException(SmsGatewayException.network);
    } catch (e) {
      throw SmsGatewayException(
        SmsGatewayException.network,
        detail: e.toString(),
      );
    }

    Map<String, dynamic> json = const {};
    if (response.body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) json = decoded;
      } catch (_) {
        // Keep the status code as the source of truth below.
      }
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const SmsGatewayException(SmsGatewayException.unauthorized);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SmsGatewayException(
        SmsGatewayException.rejected,
        detail: (json['message'] ?? json['error'] ?? 'HTTP ${response.statusCode}')
            .toString(),
      );
    }
    if (json.isEmpty) {
      throw const SmsGatewayException(SmsGatewayException.invalidResponse);
    }
    return json;
  }
}
