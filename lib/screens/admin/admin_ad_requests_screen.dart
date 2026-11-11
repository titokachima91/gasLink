import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme_ext.dart';
import '../../models/ad_models.dart';
import '../../services/ad_service.dart';
import '../../utils/formatters.dart';
import 'widgets/admin_ui.dart';

/// Admin review queue for stakeholder advertising requests.
class AdminAdRequestsScreen extends StatefulWidget {
  const AdminAdRequestsScreen({super.key});

  @override
  State<AdminAdRequestsScreen> createState() => _AdminAdRequestsScreenState();
}

class _AdminAdRequestsScreenState extends State<AdminAdRequestsScreen> {
  static const _statusLabels = {
    'new': 'New',
    'contacted': 'Contacted',
    'approved': 'Approved',
    'declined': 'Declined',
  };

  Future<void> _setStatus(AdRequest request, String status) async {
    try {
      await AdService.instance.updateAdRequestStatus(request.id, status);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update request: $error'),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri.tryParse('tel:${phone.replaceAll(RegExp(r'[^\d+]'), '')}');
    if (uri == null) return;
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ad requests'),
      ),
      body: StreamBuilder<List<AdRequest>>(
        stream: AdService.instance.streamAdRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AdminLoading();
          }
          if (snapshot.hasError) {
            return AdminErrorState(message: '${snapshot.error}');
          }
          final requests = snapshot.data ?? const <AdRequest>[];
          if (requests.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.campaign_outlined,
              title: 'No ad requests yet',
              message:
                  'Requests submitted from the "Advertise with us" screen appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final request = requests[index];
              return AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            request.company,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        AdminStatusBadge(
                          status: request.status,
                          label:
                              _statusLabels[request.status] ?? request.status,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AdminKeyValueChip(
                      label: 'Audience',
                      value: request.audience,
                    ),
                    const SizedBox(width: 6),
                    AdminKeyValueChip(
                      label: 'Placement',
                      value: request.placement,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      request.message.isEmpty ? 'No message' : request.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    if (request.budget.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Budget: TZS ${request.budget}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${request.contactPhone} · '
                            '${formatDateTime(request.createdAt)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _call(request.contactPhone),
                          icon: const Icon(Icons.call_outlined, size: 16),
                          label: const Text('Call'),
                        ),
                        TextButton(
                          onPressed: () => _setStatus(request, 'contacted'),
                          child: const Text('Mark contacted'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
