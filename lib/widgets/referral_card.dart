// lib/widgets/referral_card.dart
// Shared referral surface for consumers and vendors. Shows the user's code,
// lets them copy/share it, and (for consumers) invite a gas vendor.
// Rewards are deliberately marked "coming soon" — no balances or payouts.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme_ext.dart';
import '../services/referral_service.dart';
import 'app_ui.dart';

class ReferralCard extends StatefulWidget {
  const ReferralCard({
    super.key,
    required this.uid,
    required this.role,
    this.showVendorInvite = false,
  });

  /// Current consumer or vendor uid. Empty renders nothing.
  final String uid;

  /// `consumer` or `vendor`.
  final String role;

  /// Consumers can introduce a gas vendor through a mini-form.
  final bool showVendorInvite;

  @override
  State<ReferralCard> createState() => _ReferralCardState();
}

class _ReferralCardState extends State<ReferralCard> {
  late Future<String> _codeFuture;

  bool get _isVendor => widget.role == 'vendor';

  @override
  void initState() {
    super.initState();
    _codeFuture = _loadCode();
  }

  @override
  void didUpdateWidget(covariant ReferralCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid || oldWidget.role != widget.role) {
      _codeFuture = _loadCode();
    }
  }

  Future<String> _loadCode() {
    return ReferralService.instance.ensureCode(
      uid: widget.uid,
      role: widget.role,
    );
  }

  Future<void> _copyCode(String code) async {
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.referralCodeCopied),
        backgroundColor: context.gasColors.success,
      ),
    );
  }

  Future<void> _shareCode(String code) async {
    if (code.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final text = _isVendor
        ? l10n.referralShareVendorText(code)
        : l10n.referralShareConsumerText(code);
    await Share.share(
      text,
      subject: l10n.referralShareSubject,
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

  Future<void> _openVendorInvite() async {
    final shopCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
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
                await ReferralService.instance.inviteVendor(
                  referrerUid: widget.uid,
                  shopName: shopCtrl.text,
                  phone: phoneCtrl.text,
                );
                if (!sheetContext.mounted) return;
                Navigator.pop(sheetContext);
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.referralInviteSent),
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
                        l10n.referralInviteVendorTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.referralInviteVendorBody,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: shopCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: l10n.shopNameLabel,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? l10n.shopNameRequired
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
                              : Text(l10n.referralSendInvite),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          l10n.rewardsComingSoon,
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

    shopCtrl.dispose();
    phoneCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.uid.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isVendor ? Icons.storefront_outlined : Icons.card_giftcard,
                  color: context.colors.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isVendor
                          ? l10n.referralVendorTitle
                          : l10n.referralConsumerTitle,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isVendor
                          ? l10n.referralVendorSubtitle
                          : l10n.referralConsumerSubtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: ReferralService.instance.referralsBy(widget.uid),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return AppStatusPill(
                    label: '$count',
                    icon: Icons.group_outlined,
                    color: context.colors.primary,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<String>(
            future: _codeFuture,
            builder: (context, snapshot) {
              final code = snapshot.data ?? '······';
              return Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.referralYourCode,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            code,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4,
                              color: context.colors.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.copy,
                      icon: Icon(
                        Icons.copy_all_outlined,
                        color: context.colors.primary,
                      ),
                      onPressed:
                          snapshot.hasData ? () => _copyCode(code) : null,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () async {
                final code = await _codeFuture;
                await _shareCode(code);
              },
              icon: const Icon(Icons.share_outlined, size: 18),
              label: Text(l10n.referralShareCode),
            ),
          ),
          if (widget.showVendorInvite) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openVendorInvite,
                icon: const Icon(Icons.storefront_outlined, size: 18),
                label: Text(l10n.referralInviteGasVendor),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Center(
            child: Text(
              l10n.rewardsComingSoon,
              style: TextStyle(
                fontSize: 10.5,
                color: context.colors.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
