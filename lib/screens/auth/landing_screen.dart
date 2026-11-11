// lib/screens/auth/landing_screen.dart
// Blended landing + login: visitors learn about GasLink, and the login form
// lives right on the same page (no boring standalone login wall).

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme_ext.dart';
import '../../services/auth_service.dart';
import '../../widgets/ad_slot.dart';
import '../../widgets/app_ui.dart';
import '../advertise_screen.dart';
import '../role_router.dart';
import 'register_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scrollController = ScrollController();
  final _loginKey = GlobalKey();
  final _phone = TextEditingController();
  final _pin = TextEditingController();
  bool _loggingIn = false;
  String? _error;

  @override
  void dispose() {
    _scrollController.dispose();
    _phone.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _exploreAsGuest() async {
    await AuthService.instance.loginAsGuest();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleRouter(userRole: 'guest')),
      (_) => false,
    );
  }

  void _scrollToLogin() {
    final target = _loginKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _login() async {
    final phone = _phone.text.trim();
    final pin = _pin.text.trim();
    if (phone.isEmpty || pin.isEmpty) {
      setState(
          () => _error = 'Weka namba ya simu na PIN / Enter phone and PIN');
      return;
    }
    setState(() {
      _loggingIn = true;
      _error = null;
    });
    try {
      final data = await AuthService.instance.login(phone, pin);
      if (!mounted) return;
      final role = (data?['role'] ?? AuthService.roleConsumer) as String;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => RoleRouter(userRole: role)),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          children: [
            _buildHero(context),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Compact account entry points; "Ingia" slides the page
                  // down to reveal the login form below the details.
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: _scrollToLogin,
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('Ingia / Log in'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.person_add_alt, size: 18),
                        label: const Text('Jiandikishe / Register'),
                      ),
                      TextButton.icon(
                        onPressed: _exploreAsGuest,
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('Mgeni / Guest'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const AppSectionHeader(
                    title: 'Kwa nini GasLink? / Why GasLink?',
                    subtitle: 'Uthibitisho kabla ya ununuzi.',
                    icon: Icons.workspace_premium_outlined,
                  ),
                  const SizedBox(height: 12),
                  const _ValuePropCard(
                    icon: Icons.verified_user_outlined,
                    title: 'Wauzaji Waliohakikiwa',
                    message:
                        'Maduka yaliyothibitishwa na kukaguliwa na GasLink.',
                  ),
                  const SizedBox(height: 10),
                  const _ValuePropCard(
                    icon: Icons.local_shipping_outlined,
                    title: 'Usafirishaji Mpaka Mlango',
                    message:
                        'Agiza mtungi au kujaza gesi, tunakuletea nyumbani.',
                  ),
                  const SizedBox(height: 10),
                  const _ValuePropCard(
                    icon: Icons.price_check_outlined,
                    title: 'Bei za Soko',
                    message: 'Linganisha bei za wauzaji wote kabla hujaagiza.',
                  ),
                  const SizedBox(height: 22),
                  const AppSectionHeader(
                    title: 'Inavyofanya kazi / How it works',
                    icon: Icons.auto_awesome_outlined,
                  ),
                  const SizedBox(height: 12),
                  const _StepRow(
                    step: '1',
                    title: 'Chagua huduma',
                    message: 'Refill, mtungi mpya, vifaa au matengenezo.',
                  ),
                  const _StepRow(
                    step: '2',
                    title: 'Linganisha wauzaji',
                    message: 'Bei, umbali na uhakiki wa kila duka.',
                  ),
                  const _StepRow(
                    step: '3',
                    title: 'Agiza & Fuatilia',
                    message: 'Fuatilia oda yako mpaka mlangoni.',
                  ),
                  const SizedBox(height: 22),
                  const AppSectionHeader(
                    title: 'Tunahudumia / We serve',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final district in AppConstants.districts)
                        AppStatusPill(
                          label: district,
                          icon: Icons.place_outlined,
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const AdSlot(placementId: 'landing'),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AdvertiseScreen(),
                          ),
                        );
                      },
                      child: const Text('Tangaza nasi / Advertise with us'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildLoginSection(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.primary,
            Color.lerp(context.colors.primary, Colors.black, 0.25)!,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/gaslinklogo.png',
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  size: 44,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gesi Mkononi. Uthibitisho Kabla ya Ununuzi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Wauzaji waliothibitishwa, bei za soko, na usafirishaji mpaka mlangoni wa LPG katika Dar es Salaam.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact login form at the bottom of the landing page. The "Ingia" link
  /// at the top scrolls here.
  Widget _buildLoginSection(BuildContext context) {
    return AppCard(
      key: _loginKey,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ingia / Log in',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            'Weka namba ya simu na PIN yako.',
            style: TextStyle(
              fontSize: 12,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Namba ya Simu / Phone',
              hintText: 'e.g. 0767304776',
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pin,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            decoration: const InputDecoration(
              labelText: 'PIN',
              counterText: '',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 12,
                color: context.colors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _loggingIn ? null : _login,
              child: _loggingIn
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Ingia / Log in',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text('Huna akaunti? Jiandikishe / Register'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValuePropCard extends StatelessWidget {
  const _ValuePropCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: context.colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.title,
    required this.message,
  });

  final String step;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: TextStyle(
                color: context.colors.onPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
