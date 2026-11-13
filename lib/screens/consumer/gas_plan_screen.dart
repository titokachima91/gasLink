// lib/screens/consumer/gas_plan_screen.dart
// Discreet "GasPlan kwa Waajiriwa" teaser. No billing logic: collects employer
// interest in the `ajira_interest` collection and lets employees share the
// concept with HR. Reachable only from Consumer Settings -> Features.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme_ext.dart';
import '../../widgets/app_ui.dart';

class GasPlanScreen extends StatefulWidget {
  const GasPlanScreen({super.key});

  @override
  State<GasPlanScreen> createState() => _GasPlanScreenState();
}

class _GasPlanScreenState extends State<GasPlanScreen> {
  Future<void> _shareWithHr() async {
    final l10n = AppLocalizations.of(context);
    await Share.share(
      l10n.gasPlanShareText,
      subject: l10n.gasPlanShareSubject,
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
        final l10n = AppLocalizations.of(sheetContext);
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
                    content: Text(l10n.gasPlanThanks),
                    backgroundColor: this.context.gasColors.success,
                  ),
                );
              } catch (e) {
                if (!sheetContext.mounted) return;
                setSheetState(() => saving = false);
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(
                    content: Text(l10n.errorWithDetail('$e')),
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
                      Text(
                        l10n.gasPlanRegisterTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.gasPlanRegisterBody,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: l10n.yourName,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? l10n.nameRequired
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: l10n.phoneLabel,
                          hintText: '0767304776',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final phone = value?.trim() ?? '';
                          if (phone.length < 9) {
                            return l10n.phoneInvalid;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: employerCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: l10n.employerOptional,
                          border: const OutlineInputBorder(),
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
                              : Text(l10n.submitInfo),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          l10n.gasPlanNoPayment,
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          l10n.gasPlanTitle,
          style: const TextStyle(
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
          AppSectionHeader(
            title: l10n.gasPlanHowItWorks,
            icon: Icons.auto_awesome_outlined,
          ),
          const SizedBox(height: 10),
          _PlanStep(
            step: '1',
            title: l10n.gasPlanStep1Title,
            message: l10n.gasPlanStep1Body,
          ),
          _PlanStep(
            step: '2',
            title: l10n.gasPlanStep2Title,
            message: l10n.gasPlanStep2Body,
          ),
          _PlanStep(
            step: '3',
            title: l10n.gasPlanStep3Title,
            message: l10n.gasPlanStep3Body,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppStatusPill(
                label: l10n.gasPlanPillReliable,
                icon: Icons.verified_outlined,
              ),
              AppStatusPill(
                label: l10n.gasPlanPillPayslip,
                icon: Icons.receipt_long_outlined,
              ),
              AppStatusPill(
                label: l10n.gasPlanPillNoCash,
                icon: Icons.payments_outlined,
              ),
              AppStatusPill(
                label: l10n.gasPlanPillMonthly,
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
                    Text(
                      l10n.gasPlanExampleTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.gasPlanExampleBody,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                AppStatusPill(
                  label: l10n.gasPlanRewardsSoon,
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
            label: Text(l10n.gasPlanRegisterTitle),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _shareWithHr,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.share_outlined),
            label: Text(l10n.gasPlanShareWithHr),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              l10n.gasPlanFooter,
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
    final l10n = AppLocalizations.of(context);
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
            child: Text(
              l10n.comingSoon,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.gasPlanHeroTitle,
            style: const TextStyle(
              fontSize: 20,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.gasPlanHeroBody,
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
