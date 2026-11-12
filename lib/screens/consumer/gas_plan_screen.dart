// lib/screens/consumer/gas_plan_screen.dart
// Discreet "GasPlan kwa Waajiriwa" teaser. No billing logic: collects employer
// interest in the `ajira_interest` collection and lets employees share the
// concept with HR. Reachable only from Consumer Settings -> Features.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme_ext.dart';
import '../../widgets/app_ui.dart';

class GasPlanScreen extends StatefulWidget {
  const GasPlanScreen({super.key});

  @override
  State<GasPlanScreen> createState() => _GasPlanScreenState();
}

class _GasPlanScreenState extends State<GasPlanScreen> {
  static const _shareText =
      'GasPlan kwa Waajiriwa — gesi ya uhakika kila mwezi, malipo kupitia '
      'payslip. Inakuja hivi karibuni kwenye GasLink. Wasiliana nasi kwa '
      '0767304776 kupanga mpango wa wafanyakazi wenu.';

  Future<void> _shareWithHr() async {
    await Share.share(
      _shareText,
      subject: 'GasPlan kwa Waajiriwa — GasLink',
      sharePositionOrigin: _shareOrigin(context),
    );
  }

  Rect? _shareOrigin(BuildContext context) {
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    return null;
  }

  Future<void> _openInterestForm() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final employerCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submit() async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              setSheetState(() => saving = true);
              try {
                await FirebaseFirestore.instance
                    .collection('ajira_interest')
                    .add({
                  'name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'employer': employerCtrl.text.trim(),
                  'source': 'consumer_settings_gasplan',
                  'status': 'new',
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (!sheetContext.mounted) return;
                Navigator.pop(sheetContext);
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Asante! Tutawasiliana nawe GasPlan inapoanza.',
                    ),
                    backgroundColor: this.context.gasColors.success,
                  ),
                );
              } catch (e) {
                if (!sheetContext.mounted) return;
                setSheetState(() => saving = false);
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(
                    content: Text('Hitilafu / Error: $e'),
                    backgroundColor: sheetContext.colors.error,
                  ),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ongea nasi / Register interest',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tuma taarifa zako; tutawasiliana na mwajiri wako '
                        'kuhusu mpango huu.',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Jina lako / Your name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Weka jina lako'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Namba ya simu / Phone',
                          hintText: '0767304776',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final phone = value?.trim() ?? '';
                          if (phone.length < 9) {
                            return 'Weka namba sahihi ya simu';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: employerCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Mwajiri / Employer (hiari)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: saving ? null : submit,
                          child: saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Tuma taarifa / Submit'),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          'Hakuna malipo yanayohitajika sasa.',
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
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    phoneCtrl.dispose();
    employerCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'GasPlan kwa Waajiriwa',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHero(context),
          const SizedBox(height: 22),
          const AppSectionHeader(
            title: 'Jinsi Inavyofanya Kazi / How it works',
            icon: Icons.auto_awesome_outlined,
          ),
          const SizedBox(height: 10),
          const _PlanStep(
            step: '1',
            title: 'Mwajiri anasaini makubaliano',
            message: 'HR na GasLink hukubaliana kuhusu mpango wa wafanyakazi.',
          ),
          const _PlanStep(
            step: '2',
            title: 'Mfanyakazi anachagua mpango',
            message: 'Mitungi kwa mwezi na ratiba ya kufikishwa.',
          ),
          const _PlanStep(
            step: '3',
            title: 'Gesi inawasili kila mwezi',
            message: 'Malipo hukatwa kwenye payslip — hakuna fedha taslimu.',
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppStatusPill(
                label: 'Gesi ya uhakika',
                icon: Icons.verified_outlined,
              ),
              AppStatusPill(
                label: 'Payslip deduction',
                icon: Icons.receipt_long_outlined,
              ),
              AppStatusPill(
                label: 'Hakuna cash',
                icon: Icons.payments_outlined,
              ),
              AppStatusPill(
                label: 'Mpango wa mwezi',
                icon: Icons.calendar_month_outlined,
              ),
            ],
          ),
          const SizedBox(height: 22),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 18,
                      color: context.colors.primary,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Mfano wa mpango',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Mitungi 2 ya LPG kwa mwezi kwa kila mfanyakazi '
                  'aliyejisajili. Bei na ukubwa wa mitungi hukubaliwa na '
                  'mwajiri wako.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                const AppStatusPill(
                  label: 'Zawadi na punguzo zinakuja hivi karibuni',
                  icon: Icons.card_giftcard_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _openInterestForm,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.handshake_outlined),
            label: const Text('Ongea nasi / Register interest'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _shareWithHr,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share with your HR'),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Huduma hii bado haijaanza. Tuma taarifa yako tukuwasiliane '
              'ilipoanza.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: context.colors.outline,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.primary,
            Color.lerp(context.colors.primary, Colors.black, 0.28)!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Inakuja hivi karibuni / Coming soon',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Gesi ya uhakika kila mwezi.\nMalipo kupitia payslip.',
            style: TextStyle(
              fontSize: 20,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'GasPlan kwa Waajiriwa huwawezesha wafanyakazi kupata gesi '
            'bila kushughulika na fedha taslimu kila mwezi.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: Colors.white.withOpacity(0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanStep extends StatelessWidget {
  const _PlanStep({
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
                    fontSize: 13.5,
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
