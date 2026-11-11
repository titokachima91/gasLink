import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme_ext.dart';
import '../models/ad_models.dart';
import '../screens/advertise_screen.dart';
import '../services/ad_service.dart';
import '../services/auth_service.dart';

/// Audience-aware, non-intrusive ad banner.
///
/// Reads the placement for [placementId] and only renders when the campaign
/// targets the active role. When no campaign exists it shows the "Advertise
/// Here" pitch placeholder. Always dismissible per app session.
class AdSlot extends StatefulWidget {
  const AdSlot({super.key, required this.placementId, this.loader, this.role});

  final String placementId;

  /// Test hook: overrides the Firestore loader.
  final Future<AdPlacement?> Function()? loader;

  /// Test hook: overrides the active role.
  final String? role;

  @override
  State<AdSlot> createState() => _AdSlotState();
}

class _AdSlotState extends State<AdSlot> {
  static final Set<String> _dismissed = {};

  AdPlacement? _placement;
  bool _loading = true;

  String? get _role => widget.role ?? AuthService.instance.currentRole;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    AdPlacement? placement;
    try {
      placement = widget.loader != null
          ? await widget.loader!()
          : await AdService.instance.fetchPlacement(widget.placementId);
    } catch (error) {
      debugPrint('AdSlot load failed for ${widget.placementId}: $error');
    }
    if (!mounted) return;
    setState(() {
      _placement = placement;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed.contains(widget.placementId) || _loading) {
      return const SizedBox.shrink();
    }
    final placement = _placement;
    if (placement == null ||
        !AdService.matchesAudience(placement.audience, _role)) {
      return _buildPlaceholder(context);
    }
    return _buildBanner(context, placement);
  }

  Widget _buildBanner(BuildContext context, AdPlacement placement) {
    final linkUrl = placement.linkUrl?.trim() ?? '';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer.withOpacity(
          context.isDark ? 0.35 : 0.45,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: linkUrl.isEmpty ? null : () => _open(linkUrl),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'AD',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            placement.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (placement.subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        placement.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (placement.ctaText.trim().isNotEmpty && linkUrl.isNotEmpty)
                TextButton(
                  onPressed: () => _open(linkUrl),
                  child: Text(
                    placement.ctaText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              IconButton(
                tooltip: 'Funga / Dismiss',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.close,
                  size: 16,
                  color: context.colors.onSurfaceVariant,
                ),
                onPressed: () => setState(
                  () => _dismissed.add(widget.placementId),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The pitch asset shown when no campaign targets this audience.
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdvertiseScreen()),
          );
        },
        child: Row(
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 18,
              color: context.colors.outline,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Advertise Here — Tangaza biashara yako na GasLink',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: context.colors.outline,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
