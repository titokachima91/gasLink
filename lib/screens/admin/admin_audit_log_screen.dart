import 'package:flutter/material.dart';

import '../../core/theme_ext.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../utils/formatters.dart';
import 'widgets/admin_ui.dart';

class AdminAuditLogScreen extends StatelessWidget {
  const AdminAuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit trail')),
      body: StreamBuilder<List<AdminAuditLog>>(
        stream: AdminService.instance.streamAuditLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AdminLoading();
          }
          if (snapshot.hasError) {
            return AdminErrorState(message: '${snapshot.error}');
          }
          final logs = snapshot.data ?? const <AdminAuditLog>[];
          if (logs.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.history,
              title: 'No admin actions yet',
              message:
                  'Vendor reviews, order cancellations and settings changes will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final log = logs[index];
              final icon = _icon(log.action);
              return AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: context.colors.primaryContainer,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            icon,
                            size: 19,
                            color: context.colors.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _label(log.action),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${log.entityType} · ${shortId(log.entityId, length: 14)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatDateTime(log.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (log.reason.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Text(
                        log.reason,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Actor ${shortId(log.actorUid)} · ${log.actorRole}',
                      style: TextStyle(
                        fontSize: 10,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    if (log.before.isNotEmpty || log.after.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Before: ${_mapSummary(log.before)}'
                        '${log.after.isEmpty ? '' : '  →  After: ${_mapSummary(log.after)}'}',
                        style: TextStyle(
                          fontSize: 10,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  static IconData _icon(String action) {
    switch (action) {
      case 'approve_vendor':
        return Icons.check_circle_outline;
      case 'reject_vendor':
        return Icons.block;
      case 'suspend_vendor':
        return Icons.pause_circle_outline;
      case 'reactivate_vendor':
        return Icons.play_circle_outline;
      case 'cancel_order':
        return Icons.cancel_outlined;
      case 'update_settings':
        return Icons.tune;
      default:
        return Icons.history;
    }
  }

  static String _label(String action) {
    switch (action) {
      case 'approve_vendor':
        return 'Vendor approved';
      case 'reject_vendor':
        return 'Vendor rejected';
      case 'suspend_vendor':
        return 'Vendor suspended';
      case 'reactivate_vendor':
        return 'Vendor reactivated';
      case 'cancel_order':
        return 'Order cancelled';
      case 'update_settings':
        return 'Settings updated';
      default:
        return action.replaceAll('_', ' ');
    }
  }

  static String _mapSummary(Map<String, dynamic> map) {
    return map.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${entry.key}=${entry.value}')
        .join(', ');
  }
}
