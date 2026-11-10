import 'package:flutter/material.dart';

import '../core/theme_ext.dart';

/// Consumer-facing trust badge.
///
/// Callers must gate this widget on the vendor's stored `verified` flag; the
/// badge itself never infers verification from profile completeness or tier.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.label, this.compact = false});

  /// Optional text shown after the icon. Icon-only when null or empty.
  final String? label;

  /// Smaller variant for dense vendor cards.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = context.gasColors.info;
    final text = label?.trim() ?? '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified, size: compact ? 13 : 15, color: color),
        if (text.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
