// lib/services/otp_auth_service.dart
// Ready-to-wire SMS OTP login. Disabled until ENABLE_OTP_LOGIN=true, so the
// existing phone + PIN flow remains the only active authentication path.

import '../core/app_error.dart';
import '../core/gateway_config.dart';
import 'sms_gateway_service.dart';

class OtpAuthService {
  OtpAuthService({SmsGatewayService? gateway, bool? enabled})
      : _gateway = gateway ?? SmsGatewayService.instance,
        _enabled = enabled ?? GatewayConfig.enableOtpLogin;

  static final OtpAuthService instance = OtpAuthService();

  final SmsGatewayService _gateway;
  final bool _enabled;

  bool get isEnabled => _enabled;

  Future<OtpChallenge> requestCode(String phone) async {
    if (!_enabled) {
      throw const AppError(AppError.otpDisabled);
    }
    return _gateway.sendOtp(phone);
  }

  Future<bool> verifyCode({
    required String phone,
    required String ref,
    required String code,
  }) async {
    if (!_enabled) {
      throw const AppError(AppError.otpDisabled);
    }
    return _gateway.verifyOtp(phone: phone, ref: ref, code: code);
  }
}
