// lib/screens/legal/legal_screens.dart
// Static terms & privacy pages. Placeholder legal copy for the pilot; a
// lawyer-reviewed version replaces this before public launch.

import 'package:flutter/material.dart';

import '../../core/theme_ext.dart';
import '../../widgets/app_ui.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalPage(
      title: 'Vigezo na Masharti / Terms & Conditions',
      sections: const [
        (
          '1. Utumiaji wa huduma',
          'GasLink inakupa jukwaa la kuagiza gesi ya LPG kutoka kwa wauzaji '
              'waliothibitishwa. Kwa kutumia app, unakubali kufuata sheria na '
              'taratibu za Tanzania.'
        ),
        (
          '2. Akaunti na usalama',
          'PIN yako ni siri. Usimpe mtu yeyote. Uliwajibika kwa shughuli zote '
              'zinazofanyika kwenye akaunti yako.'
        ),
        (
          '3. Oda na malipo',
          'Bei zinaonyeshwa kabla ya kuagiza. Malipo yanafanyika kwa njia '
              'zilizoidhinishwa. Tafadhali thibitisha oda yako kwa wauzaji.'
        ),
        (
          '4. Vigezo vya ubora',
          'Wauzaji wanathibitishwa kwa mizani ya WMA na leseni halali. '
              'Ripoti matatizo yoyote kupitia msaada kwa wateja.'
        ),
        (
          '5. Matangazo na ujumbe',
          'Tunaweza kukuonyesha matangazo ndani ya app. Ujumbe wa push, '
              'vidokezo na ofa hutumwa tu ikiwa ulikubali wakati wa usajili. '
              'Unaweza kuacha kupokea ujumbe kupitia mipangilio ya simu au '
              'msaada kwa wateja.'
        ),
      ],
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalPage(
      title: 'Sera ya Faragha / Privacy Policy',
      sections: const [
        (
          '1. Taarifa tunazokusanya',
          'Namba ya simu, eneo la kupelekea oda, na maelezo ya oda zako. '
              'Hatuweki PIN yako wazi — inahifadhiwa kwa njia ya siri.'
        ),
        (
          '2. Matumizi ya taarifa',
          'Ili kukuhudumia: kuchakata oda, kukuelekeza kwa wauzaji, na '
              'kuboresha huduma.'
        ),
        (
          '3. Kushirikisha taarifa',
          'Wauzaji huona tu taarifa za oda yako. Hatouzi taarifa zako kwa '
              'watu wa nje.'
        ),
        (
          '4. Usalama',
          'Tunatumia ulinzi wa kiwango cha juu kuhifadhi taarifa zako.'
        ),
        (
          '5. Haki zako',
          'Unaweza kuomba kufuta akaunti yako wakati wowote kupitia msaada '
              'kwa wateja.'
        ),
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
              'Toleo la mwongozo · Pilot 2026',
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
