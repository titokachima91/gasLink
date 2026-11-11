// lib/screens/auth/register_screen.dart
// Branded registration: logo, phone + PIN + confirm, Terms & ads consent.

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../role_router.dart';
import 'login_screen.dart';
import 'landing_screen.dart';
import 'widgets/auth_widgets.dart';

import '../../core/theme_ext.dart';

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
  bool _adsConsent = true;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    _pin2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_pinCtrl.text.trim() != _pin2Ctrl.text.trim()) {
      setState(() => _error = 'PIN hazifanana / PINs do not match');
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
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fungua akaunti / Register'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _backToLanding,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeader(
                subtitle: 'Unda akaunti ya bure uanze kuagiza.',
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Namba ya simu / Phone number',
                  hintText: 'e.g. 0767304776',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'PIN (namba 4) / 4-digit PIN',
                  counterText: '',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pin2Ctrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Rudia PIN / Confirm PIN',
                  counterText: '',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
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
                    : const Text('Fungua akaunti / Create account'),
              ),
              if (!_termsAccepted) ...[
                const SizedBox(height: 6),
                Text(
                  'Kubali Vigezo na Masharti kuendelea.',
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
                child: const Text('Tayari una akaunti? Ingia / Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
