import 'package:flutter/material.dart';

import '../../../core/theme_ext.dart';
import '../../../models/vendor.dart';

/// Read-only billing summary shown to vendors.
///
/// Commission terms are admin-controlled; vendors can see them but never edit
/// them from the app.
class VendorCommissionTermsCard extends StatelessWidget {
  const VendorCommissionTermsCard({super.key, required this.vendor});

  final Vendor? vendor;

  @override
  Widget build(BuildContext context) {
    final v = vendor;
    final isSubscription = v?.isSubscription ?? false;
    final modelLabel = v == null
        ? 'Haijawekwa / Not set'
        : (isSubscription ? 'Monthly subscription' : 'Percentage');
    final detail =
        v == null ? 'Billing terms will appear here.' : v.commissionLabel;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isSubscription ? Icons.event_repeat : Icons.percent,
              color: context.colors.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    modelLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Inasimamiwa na GasLink / Managed by GasLink',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.gasColors.info,
                      fontWeight: FontWeight.w600,
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
}
