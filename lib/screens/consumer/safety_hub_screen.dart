// lib/screens/consumer/safety_hub_screen.dart
// Approved gas-safety content read from Firestore. The AI assistant uses the
// same collection, so the app and SMS answers stay aligned.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../core/theme_ext.dart';
import '../../widgets/app_ui.dart';

class SafetyHubScreen extends StatelessWidget {
  const SafetyHubScreen({super.key});

  static const _fallback = [
    {
      'title': 'Gas leak or smell of gas',
      'titleSw': 'Harufu ya gesi',
      'body':
          'Move outside immediately. Do not light flames or operate electrical switches. Open windows. Close the cylinder valve if it is safe. Call GasLink support on 0767304776.',
      'bodySw':
          'Toka nje sasa. Usiwasha moto wala swichi. Funga madirisha. Funga valvu ya mtungi kama ni salama. Piga support 0767304776.',
    },
    {
      'title': 'Checking if a cylinder is full',
      'titleSw': 'Kupima kama mtungi umejaa',
      'body':
          'The vendor weighs the cylinder in front of you if they have a scale. The reading should be the largest number indicated on the cylinder. Ask the vendor to explain the markings if you need details.',
      'bodySw':
          'Vendor atapima mtungi mbele yako kama ana mizani. Usomaji uwe namba kubwa zaidi iliyoonyeshwa kwenye mtungi. Muulize vendor akueleze maana ya namba zote kama unahitaji maelezo.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSwahili = Localizations.localeOf(context).languageCode == 'sw';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.safetyHub)),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('safety_guidelines')
            .where('published', isEqualTo: true)
            .get(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? const [];
          final List<Map<String, dynamic>> items = docs.isEmpty
              ? _fallback
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
              : (docs.toList()
                    ..sort((a, b) {
                      final left = (a.data()['order'] as num?)?.toInt() ?? 0;
                      final right = (b.data()['order'] as num?)?.toInt() ?? 0;
                      return left.compareTo(right);
                    }))
                  .map((doc) => doc.data())
                  .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.safetyHubSubtitle,
                style: TextStyle(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                AppCard(child: Text(l10n.safetyHubEmpty))
              else
                ...items.map((item) {
                  final title = (isSwahili
                          ? item['titleSw'] ?? item['title_sw'] ?? item['title']
                          : item['title'] ?? item['titleSw'])
                      .toString();
                  final body = (isSwahili
                          ? item['bodySw'] ?? item['body_sw'] ?? item['body']
                          : item['body'] ?? item['bodySw'])
                      .toString();
                  final stepsRaw = isSwahili
                      ? item['stepsSw'] ?? item['steps_sw'] ?? item['steps']
                      : item['steps'] ?? item['stepsSw'];
                  final steps = stepsRaw is List
                      ? stepsRaw.map((e) => e.toString()).toList()
                      : <String>[];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.health_and_safety_outlined,
                                color: context.colors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (body.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(body, style: const TextStyle(height: 1.45)),
                          ],
                          if (steps.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ...steps.map(
                              (step) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '• ',
                                      style: TextStyle(
                                        color: context.colors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Expanded(child: Text(step)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 8),
              AppCard(
                child: Row(
                  children: [
                    Icon(Icons.support_agent, color: context.colors.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'GasLink support: 0767304776',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
