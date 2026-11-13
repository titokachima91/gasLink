// lib/screens/auth/landing_screen.dart
// Visitor landing page: pitch first, then links to the dedicated login /
// register screens or guest mode. No form on this page.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../core/constants.dart';
import '../../core/theme_ext.dart';
import '../../services/auth_service.dart';
import '../../widgets/ad_slot.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/language_picker.dart';
import '../advertise_screen.dart';
import '../role_router.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'widgets/auth_widgets.dart';

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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHero(context, l10n),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account entry points; forms live on dedicated screens.
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.login, size: 18),
                        label: Text(l10n.login),
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
                        label: Text(l10n.register),
                      ),
                      TextButton.icon(
                        onPressed: () => _exploreAsGuest(context),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: Text(l10n.guest),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppSectionHeader(
                    title: l10n.whyGasLink,
                    subtitle: l10n.whyGasLinkSubtitle,
                    icon: Icons.workspace_premium_outlined,
                  ),
                  const SizedBox(height: 12),
                  _ValuePropCard(
                    icon: Icons.verified_user_outlined,
                    title: l10n.verifiedVendors,
                    message: l10n.verifiedVendorsBody,
                  ),
                  const SizedBox(height: 10),
                  _ValuePropCard(
                    icon: Icons.local_shipping_outlined,
                    title: l10n.doorDelivery,
                    message: l10n.doorDeliveryBody,
                  ),
                  const SizedBox(height: 10),
                  _ValuePropCard(
                    icon: Icons.price_check_outlined,
                    title: l10n.marketPrices,
                    message: l10n.marketPricesBody,
                  ),
                  const SizedBox(height: 22),
                  AppSectionHeader(
                    title: l10n.howItWorks,
                    icon: Icons.auto_awesome_outlined,
                  ),
                  const SizedBox(height: 12),
                  _StepRow(
                    step: '1',
                    title: l10n.stepChooseService,
                    message: l10n.stepChooseServiceBody,
                  ),
                  _StepRow(
                    step: '2',
                    title: l10n.stepCompareVendors,
                    message: l10n.stepCompareVendorsBody,
                  ),
                  _StepRow(
                    step: '3',
                    title: l10n.stepOrderTrack,
                    message: l10n.stepOrderTrackBody,
                  ),
                  const SizedBox(height: 22),
                  AppSectionHeader(
                    title: l10n.weServe,
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
                      child: Text(l10n.advertiseWithUs),
                    ),
                  ),
                  const LegalLinks(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, AppLocalizations l10n) {
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
          const Align(
            alignment: Alignment.centerRight,
            child: LanguageActionButton(color: Colors.white),
          ),
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
          Text(
            l10n.heroTagline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.heroBody,
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
