// lib/screens/auth/landing_screen.dart
// First impression for visitors: what GasLink is, why it matters, and a
// low-commitment way in (log in, register, or explore as a guest).

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme_ext.dart';
import '../../services/auth_service.dart';
import '../../widgets/ad_slot.dart';
import '../../widgets/app_ui.dart';
import '../advertise_screen.dart';
import '../role_router.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  Future<void> _exploreAsGuest(BuildContext context) async {
    await AuthService.instance.loginAsGuest();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleRouter(userRole: 'guest')),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHero(context),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 22),
                  const AppSectionHeader(
                    title: 'Anza sasa / Get started',
                    icon: Icons.rocket_launch_outlined,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Pata Gesi / Get Gas'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => _exploreAsGuest(context),
                      icon: const Icon(Icons.visibility_outlined),
                      label:
                          const Text('Chunguza kama mgeni / Explore as guest'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text('Huna akaunti? Jiandikishe / Register'),
                    ),
                  ),
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
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 34),
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.35)),
            ),
            child: const Icon(
              Icons.local_fire_department,
              size: 40,
              color: Colors.white,
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
