// lib/screens/auth/register_screen.dart
// Branded registration: logo, phone + PIN + confirm, Terms & marketing consent.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../core/theme_ext.dart';
import '../../l10n/error_messages.dart';
import '../../services/auth_service.dart';
import '../../widgets/language_picker.dart';
import '../role_router.dart';
import 'landing_screen.dart';
import 'login_screen.dart';
import 'widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _pin2Ctrl = TextEditingController();
  bool _loading = false;
  bool _termsAccepted = false;
  bool _adsConsent = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    _pin2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final l10n = AppLocalizations.of(context);
    if (_pinCtrl.text.trim() != _pin2Ctrl.text.trim()) {
      setState(() => _error = l10n.errorPinsDoNotMatch);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.register(
        _phoneCtrl.text,
        _pinCtrl.text,
        adsConsent: _adsConsent,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) => const RoleRouter(userRole: 'consumer')),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = authErrorText(AppLocalizations.of(context), e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _backToLanding() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.registerTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _backToLanding,
        ),
        actions: const [LanguageActionButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(subtitle: l10n.registerSubtitle),
              const SizedBox(height: 24),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.phoneNumber,
                  hintText: l10n.phoneHint,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: l10n.pin4,
                  counterText: '',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pin2Ctrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: l10n.confirmPin,
                  counterText: '',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              AuthConsents(
                onChanged: ({required termsAccepted, required adsConsent}) {
                  setState(() {
                    _termsAccepted = termsAccepted;
                    _adsConsent = adsConsent;
                  });
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: context.colors.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: (_loading || !_termsAccepted) ? null : _register,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.register),
              ),
              if (!_termsAccepted) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.acceptTermsPrompt,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        ),
                child: Text(l10n.alreadyHaveAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
