import 'package:flutter/material.dart';

import '../../../core/theme_ext.dart';
import '../../../widgets/app_ui.dart';
import '../../legal/legal_screens.dart';

/// Shared Terms & Conditions + advertising-consent block used by the login
/// and register screens.
class AuthConsents extends StatefulWidget {
  const AuthConsents({super.key, required this.onChanged});

  /// Called whenever either checkbox changes.
  final void Function({required bool termsAccepted, required bool adsConsent})
      onChanged;

  @override
  State<AuthConsents> createState() => _AuthConsentsState();
}

class _AuthConsentsState extends State<AuthConsents> {
  bool _termsAccepted = false;
  bool _adsConsent = true;

  void _emit() {
    widget.onChanged(
      termsAccepted: _termsAccepted,
      adsConsent: _adsConsent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            value: _termsAccepted,
            activeColor: context.colors.primary,
            title: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Nakubali Vigezo na Masharti',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TermsScreen()),
                  ),
                  child: const Text(
                    'Soma',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            onChanged: (value) {
              setState(() => _termsAccepted = value ?? false);
              _emit();
            },
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            value: _adsConsent,
            activeColor: context.colors.primary,
            title: const Text(
              'Nakubali kupokea matangazo na ofa',
              style: TextStyle(fontSize: 12.5),
            ),
            subtitle: const Text(
              'Unaweza kubadilisha hii kwenye Mipangilio.',
              style: TextStyle(fontSize: 11),
            ),
            onChanged: (value) {
              setState(() => _adsConsent = value ?? false);
              _emit();
            },
          ),
        ],
      ),
    );
  }
}

/// Logo + app name block shared by the auth screens.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/gaslinklogo.png',
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_fire_department,
                size: 36,
                color: context.colors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'GasLink',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
