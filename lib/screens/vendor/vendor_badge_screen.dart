/// ============================================================================
/// FILE: lib/screens/vendor/vendor_badge_screen.dart
///
/// SUMMARY:
/// Visual progress tracker for vendor certification & tier badges ("Tuzo na Uthibitisho").
/// Streams live Firestore vendor data to evaluate Tier 1, 2, and 3 criteria,
/// rendering an interactive checklist and direct "Kamilisha Sasa" actions.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'vendor_profile_screen.dart';

import '../../core/theme_ext.dart';

class VendorBadgeScreen extends StatefulWidget {
  const VendorBadgeScreen({super.key});

  @override
  State<VendorBadgeScreen> createState() => _VendorBadgeScreenState();
}

class _VendorBadgeScreenState extends State<VendorBadgeScreen> {
  String get _vendorUid =>
      FirebaseAuth.instance.currentUser?.uid ??
      AuthService.instance.currentUserId ??
      '';

  @override
  Widget build(BuildContext context) {
    if (_vendorUid.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Tafadhali ingia kama muuzaji')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Tuzo na Uthibitisho / Badges',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('vendors')
            .doc(_vendorUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: context.colors.primary),
            );
          }

          final data = snapshot.data?.data() ?? {};
          final int currentTier = (data['badgeTier'] as num?)?.toInt() ??
              (data['tier'] as num?)?.toInt() ??
              1;
          final int completionPercentage =
              (data['completionPercentage'] as num?)?.toInt() ?? 65;

          // Proof field checks (handles both text strings and URL uploads)
          final bool hasWmaSticker =
              (data['wmaStickerUrl'] as String? ?? '').trim().isNotEmpty ||
                  (data['wmaScaleSticker'] as String? ?? '').trim().isNotEmpty;
          final bool hasLicense =
              (data['businessLicenseUrl'] as String? ?? '').trim().isNotEmpty ||
                  (data['municipalLicense'] as String? ?? '').trim().isNotEmpty;
          final bool hasSuperDealerProof =
              (data['superDealerProofUrl'] as String? ?? '')
                      .trim()
                      .isNotEmpty ||
                  (data['superDealerProof'] as String? ?? '').trim().isNotEmpty;
          final bool hasStorefrontPhoto =
              (data['imageUrl'] as String? ?? '').trim().isNotEmpty ||
                  (data['photoUrl'] as String? ?? '').trim().isNotEmpty;

          // Tier 1 criteria computed from real data (display only; the
          // authoritative tier calculation lives in the Vendor model).
          final List<String> services =
              ((data['offeredServices'] as List?) ?? const [])
                  .whereType<String>()
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
          final bool hasCoreInfo =
              (data['businessName'] as String? ?? '').trim().isNotEmpty &&
                  (data['phone'] as String? ?? '').trim().isNotEmpty;
          final bool hasLocation =
              (data['district'] as String? ?? '').trim().isNotEmpty &&
                  (data['latitude'] as num?) != null;
          final bool hasScale = data['hasOperationalScale'] as bool? ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Motivation Card ─────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).appBarTheme.backgroundColor!,
                        Theme.of(context).appBarTheme.backgroundColor!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.primaryContainer,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.workspace_premium,
                              size: 36,
                              color: context.colors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hali ya Duka Lako',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Tier $currentTier: ${currentTier == 1 ? "Muuza Gesi" : currentTier == 2 ? "Muuzaji Aliyethibitishwa" : "Muuzaji Aliyeaminika"}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ukamilifu wa Profaili',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            '$completionPercentage%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: completionPercentage / 100,
                          backgroundColor: Colors.white30,
                          color: Colors.white,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '💡 Weka Taarifa za WMA, Leseni, na Distributor Invoice ili upande Tier 2!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Hatua za Vyeti na Badges',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // ── Tier 1 Card ──────────────────────────────────────
                _buildTierCard(
                  context: context,
                  tierNumber: 1,
                  title: 'Tier 1: Muuza Gesi',
                  subtitle: 'Kiwango cha Msingi cha Biashara',
                  badgeIcon: Icons.store,
                  badgeColor: context.gasColors.info,
                  isCompleted: currentTier > 1,
                  isCurrent: currentTier == 1,
                  benefits: const [
                    'Orodheshwa kwenye App',
                    'Pokea Oda za Wateja',
                    'Alama ya Mizani',
                  ],
                  requirements: [
                    {'title': 'Taarifa Kuu za Duka', 'done': hasCoreInfo},
                    {'title': 'Eneo & GPS Coordinates', 'done': hasLocation},
                    {'title': 'Mizani Inafanya Kazi', 'done': hasScale},
                    {
                      'title': 'Huduma 2+ za Wateja Selected',
                      'done': services.length >= 2,
                    },
                  ],
                  onTapAction: () => _navigateToProfile(context),
                ),
                const SizedBox(height: 16),

                // ── Tier 2 Card ──────────────────────────────────────
                _buildTierCard(
                  context: context,
                  tierNumber: 2,
                  title: 'Tier 2: Muuzaji Aliyethibitishwa',
                  subtitle: 'Badge ya Uthibitisho na Uaminifu',
                  badgeIcon: Icons.verified,
                  badgeColor: context.gasColors.success,
                  isCompleted: currentTier > 2,
                  isCurrent: currentTier == 2,
                  benefits: const [
                    'Badge ya Kijani ya Verified',
                    'Onyeshwa Mbele ya Matokeo ya Utafutaji',
                    'Uaminifu Mkubwa kwa Wateja',
                  ],
                  requirements: [
                    const {'title': 'Ukamilifu wa Tier 1', 'done': true},
                    {
                      'title': 'Sticker ya Mizani ya WMA (WMA Scale Sticker)',
                      'done': hasWmaSticker,
                    },
                    {
                      'title': 'Leseni ya Biashara (Municipal License)',
                      'done': hasLicense,
                    },
                    {
                      'title': 'Risiti/Invoisi ya Super-Dealer Proof',
                      'done': hasSuperDealerProof,
                    },
                  ],
                  actionLabel: 'Kamilisha Sasa / Upload Proofs',
                  onTapAction: () => _navigateToProfile(context),
                ),
                const SizedBox(height: 16),

                // ── Tier 3 Card ──────────────────────────────────────
                _buildTierCard(
                  context: context,
                  tierNumber: 3,
                  title: 'Tier 3: Muuzaji Aliyeaminika',
                  subtitle: 'Kiwango cha Juu Cha Ubora',
                  badgeIcon: Icons.workspace_premium,
                  badgeColor: context.gasColors.warning,
                  isCompleted: currentTier == 3,
                  isCurrent: currentTier == 3,
                  benefits: const [
                    'Gold Badge ya Aliyeaminika',
                    'Nasiha ya Kwanza kwenye Mapendekezo',
                    'Ulinzi wa Consumer Protection Protocol',
                  ],
                  requirements: [
                    {'title': 'Ukamilifu wa Tier 2', 'done': currentTier >= 2},
                    {
                      'title': 'Picha ya Duka Front / Banner',
                      'done': hasStorefrontPhoto,
                    },
                    const {'title': 'Oda zilizokamilika (50+)', 'done': false},
                  ],
                  actionLabel: currentTier >= 2
                      ? 'Kamilisha Profiling'
                      : 'Inahitaji Tier 2 Kwanza',
                  onTapAction: currentTier >= 2
                      ? () => _navigateToProfile(context)
                      : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VendorProfileScreen()),
    );
  }

  Widget _buildTierCard({
    required BuildContext context,
    required int tierNumber,
    required String title,
    required String subtitle,
    required IconData badgeIcon,
    required Color badgeColor,
    required bool isCompleted,
    required bool isCurrent,
    required List<String> benefits,
    required List<Map<String, dynamic>> requirements,
    String? actionLabel,
    VoidCallback? onTapAction,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrent
              ? context.colors.primary
              : isCompleted
                  ? context.gasColors.success
                  : context.colors.outlineVariant,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(badgeIcon, color: badgeColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                            fontSize: 11,
                            color: context.colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Chip(
                    label: Text(
                      'Kamilifu',
                      style: TextStyle(
                          color: context.gasColors.onSuccess, fontSize: 10),
                    ),
                    backgroundColor: context.gasColors.success,
                    visualDensity: VisualDensity.compact,
                  )
                else if (isCurrent)
                  Chip(
                    label: Text(
                      'Inafanya Kazi',
                      style: TextStyle(
                          color: context.colors.onPrimary, fontSize: 10),
                    ),
                    backgroundColor: context.colors.primary,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              'Faida za Kiwango Hiki:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 6),
            ...benefits.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.star,
                        size: 14, color: context.gasColors.warning),
                    const SizedBox(width: 6),
                    Text(b, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Vigezo / Requirements:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 6),
            ...requirements.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    Icon(
                      r['done'] == true
                          ? Icons.check_circle
                          : Icons.cancel_outlined,
                      size: 16,
                      color: r['done'] == true
                          ? context.gasColors.success
                          : context.colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        r['title'].toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: r['done'] == true
                              ? context.colors.onSurface
                              : context.colors.onSurfaceVariant,
                          decoration: r['done'] == true
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: onTapAction != null
                        ? context.colors.primary
                        : context.colors.outlineVariant,
                    elevation: 0,
                  ),
                  onPressed: onTapAction,
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      color: onTapAction != null
                          ? context.colors.onPrimary
                          : context.colors.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
