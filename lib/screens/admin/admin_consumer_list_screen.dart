import 'package:flutter/material.dart';

import '../../core/theme_ext.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../utils/formatters.dart';
import 'widgets/admin_ui.dart';
import 'admin_consumer_detail_screen.dart';

class AdminConsumerListScreen extends StatefulWidget {
  const AdminConsumerListScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminConsumerListScreen> createState() =>
      _AdminConsumerListScreenState();
}

class _AdminConsumerListScreenState extends State<AdminConsumerListScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = StreamBuilder<List<AdminConsumer>>(
      stream: AdminService.instance.streamConsumers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoading();
        }
        if (snapshot.hasError) {
          return AdminErrorState(message: '${snapshot.error}');
        }
        final all = snapshot.data ?? const <AdminConsumer>[];
        final query = _search.text.trim().toLowerCase();
        final filtered = all.where((consumer) {
          final haystack = [
            consumer.displayName,
            consumer.phone,
            consumer.uid,
          ].join(' ').toLowerCase();
          return query.isEmpty || haystack.contains(query);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: AdminSearchField(
                      controller: _search,
                      hint: 'Search phone, name or UID',
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AdminKeyValueChip(
                    label: 'Total',
                    value: '${all.length}',
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? AdminEmptyState(
                      icon: Icons.people_alt_outlined,
                      title: all.isEmpty
                          ? 'No consumers yet'
                          : 'No consumers match this search',
                      message: all.isEmpty
                          ? 'Registered consumer accounts will appear here.'
                          : 'Try a phone number or UID.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final consumer = filtered[index];
                        return AdminCard(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminConsumerDetailScreen(
                                uid: consumer.uid,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              AdminAvatar(name: consumer.displayName),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      consumer.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      consumer.phone.isEmpty
                                          ? consumer.uid
                                          : consumer.phone,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.colors.onSurfaceVariant,
                                      ),
                                    ),
                                    if (consumer.createdAt != null) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        'Joined ${formatDate(consumer.createdAt)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              context.colors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right,
                                  color: context.colors.outline),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Consumers')),
      body: body,
    );
  }
}
