// lib/screens/auth/otp_verification_screen.dart
// Placeholder SMS OTP verification screen, wired to the gateway but hidden
// behind ENABLE_OTP_LOGIN=false. Phone + PIN remains the active login path.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../core/theme_ext.dart';
import '../../l10n/error_messages.dart';
import '../../services/otp_auth_service.dart';
import '../../services/sms_gateway_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key, required this.phone});

  final String phone;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  final OtpAuthService _otp = OtpAuthService.instance;

  OtpChallenge? _challenge;
  bool _sending = false;
  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_otp.isEnabled) {
      _sendCode();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final challenge = await _otp.requestCode(widget.phone);
      if (!mounted) return;
      setState(() => _challenge = challenge);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is SmsGatewayException
            ? AppLocalizations.of(context).otpSendFailed
            : authErrorText(AppLocalizations.of(context), e);
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    final challenge = _challenge;
    final code = _codeController.text.trim();
    if (challenge == null || code.length != 6 || _verifying) return;

    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final verified = await _otp.verifyCode(
        phone: widget.phone,
        ref: challenge.ref,
        code: code,
      );
      if (!mounted) return;
      if (!verified) {
        setState(() => _error = AppLocalizations.of(context).otpInvalid);
        return;
      }
      // Wiring point for the future auth handshake. Until then this screen is
      // unreachable because ENABLE_OTP_LOGIN defaults to false.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is SmsGatewayException
            ? AppLocalizations.of(context).otpInvalid
            : authErrorText(AppLocalizations.of(context), e);
      });
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final enabled = _otp.isEnabled;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.otpLoginTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            Icons.sms_outlined,
            size: 56,
            color: context.colors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            enabled ? l10n.otpLoginBody(widget.phone) : l10n.otpDisabled,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _codeController,
            enabled: enabled,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, letterSpacing: 8),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.otpCodeLabel,
              border: const OutlineInputBorder(),
              counterText: '',
            ),
            onSubmitted: (_) => _verify(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: context.colors.error),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: enabled && !_verifying ? _verify : null,
            child: _verifying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.otpVerify),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: enabled && !_sending ? _sendCode : null,
            child: Text(_sending ? l10n.otpSending : l10n.otpResend),
          ),
        ],
      ),
    );
  }
}
