// lib/screens/auth/login_screen.dart
// Branded login screen: logo, phone + PIN, and links to register, guest mode,
// and the landing page.

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../role_router.dart';
import '../../widgets/theme_mode_button.dart';
import 'register_screen.dart';
import 'landing_screen.dart';
import 'widgets/auth_widgets.dart';

import '../../core/theme_ext.dart';

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
      if (data == null) {
        setState(() => _error = 'Ingia imeshindikana / Login failed');
        return;
      }

      final role = data['role'] as String?;
      if (role == null || !AuthService.validRoles.contains(role)) {
        setState(() => _error =
            'Akaunti haina wadhifa sahihi / Account role is not configured');
        return;
      }

      // Consent is collected at registration only.
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => RoleRouter(userRole: role)),
        (_) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _backToLanding();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Karibu / Welcome'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _backToLanding,
          ),
          actions: const [ThemeModeButton()],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeader(subtitle: 'Gesi mkononi, uthibitisho kwanza.'),
                const SizedBox(height: 24),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Namba ya simu / Phone number',
                    hintText: '+255777000777',
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
                      : const Text('Ingia / Login'),
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
                  child: const Text('Fungua akaunti / Register'),
                ),
                TextButton(
                  onPressed: _loading ? null : _guest,
                  child: Text(
                    'Endelea bila kuingia / Continue without account',
                    style: TextStyle(color: context.colors.onSurfaceVariant),
                  ),
                ),
                const LegalLinks(),
                Center(
                  child: Text(
                    '🔒 PIN yako ni siri. Data salama na GasLink.',
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
