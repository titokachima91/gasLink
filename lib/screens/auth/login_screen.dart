// lib/screens/auth/login_screen.dart
// Branded login screen: logo, phone + PIN, and links to register, guest mode,
// and the landing page.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../core/theme_ext.dart';
import '../../l10n/error_messages.dart';
import '../../services/auth_service.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/theme_mode_button.dart';
import '../role_router.dart';
import 'landing_screen.dart';
import 'register_screen.dart';
import 'widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AuthService.instance.login(
        _phoneCtrl.text.trim(),
        _pinCtrl.text.trim(),
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      if (data == null) {
        setState(() => _error = l10n.loginFailed);
        return;
      }

      final role = data['role'] as String?;
      if (role == null || !AuthService.validRoles.contains(role)) {
        setState(() => _error = l10n.accountRoleMissing);
        return;
      }

      // Consent is collected at registration only.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => RoleRouter(userRole: role)),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = authErrorText(AppLocalizations.of(context), e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _guest() async {
    await AuthService.instance.loginAsGuest();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleRouter(userRole: 'guest')),
      (_) => false,
    );
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _backToLanding();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.welcome),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _backToLanding,
          ),
          actions: const [LanguageActionButton(), ThemeModeButton()],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHeader(subtitle: l10n.appTagline),
                const SizedBox(height: 24),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.phoneNumber,
                    hintText: '+255777000777',
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
                const SizedBox(height: 12),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: context.colors.error)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.login),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          ),
                  child: Text(l10n.register),
                ),
                TextButton(
                  onPressed: _loading ? null : _guest,
                  child: Text(
                    l10n.continueWithoutAccount,
                    style: TextStyle(color: context.colors.onSurfaceVariant),
                  ),
                ),
                const LegalLinks(),
                Center(
                  child: Text(
                    l10n.pinPrivacyNote,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colors.outline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
