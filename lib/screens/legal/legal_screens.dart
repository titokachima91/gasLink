// lib/screens/legal/legal_screens.dart
// Static terms & privacy pages. Placeholder legal copy for the pilot; a
// lawyer-reviewed version replaces this before public launch.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../core/theme_ext.dart';
import '../../widgets/app_ui.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _LegalPage(
      title: l10n.terms,
      sections: [
        (l10n.termsSection1Title, l10n.termsSection1Body),
        (l10n.termsSection2Title, l10n.termsSection2Body),
        (l10n.termsSection3Title, l10n.termsSection3Body),
        (l10n.termsSection4Title, l10n.termsSection4Body),
        (l10n.termsSection5Title, l10n.termsSection5Body),
      ],
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _LegalPage(
      title: l10n.privacy,
      sections: [
        (l10n.privacySection1Title, l10n.privacySection1Body),
        (l10n.privacySection2Title, l10n.privacySection2Body),
        (l10n.privacySection3Title, l10n.privacySection3Body),
        (l10n.privacySection4Title, l10n.privacySection4Body),
        (l10n.privacySection5Title, l10n.privacySection5Body),
      ],
    );
  }
}

class _LegalPage extends StatelessWidget {
  const _LegalPage({required this.title, required this.sections});

  final String title;
  final List<(String, String)> sections;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (heading, body) in sections) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heading,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Center(
            child: Text(
              l10n.legalGuideFooter,
              style: TextStyle(
                fontSize: 11,
                color: context.colors.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
