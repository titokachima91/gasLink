// ============================================================================
// FILE PATH: lib/screens/consumer/consumer_orders_history_screen.dart
// ROLE: Complete order archive showing active, delivered, cancelled, and past orders.
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import 'consumer_order_screen.dart';

import '../../core/theme_ext.dart';

class ConsumerOrdersHistoryScreen extends StatelessWidget {
  final String consumerUid;

  const ConsumerOrdersHistoryScreen({super.key, required this.consumerUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Historia ya Oda Zangu / Orders History',
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: OrderService.instance.consumerOrders(consumerUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: context.colors.primary));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: context.colors.outline),
                  const SizedBox(height: 12),
                  Text(
                    'Huna historia ya oda bado',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Oda zote utakazofanya zitaonekana hapa.',
                    style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final orderId = doc.id;

              final brand = (data['brand'] ?? 'Gesi').toString();
              final size =
                  (data['size'] ?? data['weight'] ?? '15kg').toString();
              final total =
                  (data['total'] ?? data['total_price'] ?? 0.0) as num;
              final status =
                  (data['status'] ?? 'placed').toString().toLowerCase().trim();
              final intent = (data['order_intent'] ?? 'new_asset').toString();

              // Handle Firestore timestamp safely
              DateTime createdAt = DateTime.now();
              final rawTimestamp = data['created_at'] ?? data['createdAt'];
              if (rawTimestamp is Timestamp) {
                createdAt = rawTimestamp.toDate();
              }

              // Determine status badge color and label
              Color badgeColor = context.colors.primary;
              String statusLabel = 'Inasubiri';

              if (status == 'delivered' || status == 'completed') {
                badgeColor = context.gasColors.success;
                statusLabel = 'Imekamilika';
              } else if (status == 'on_the_way' || status == 'in_transit') {
                badgeColor = context.colors.tertiary;
                statusLabel = 'Ipo Njiani';
              } else if (status == 'confirmed' ||
                  status == 'accepted' ||
                  status == 'preparing' ||
                  status == 'seen') {
                badgeColor = context.colors.secondary;
                statusLabel = 'Inaendelea / Inaandaliwa';
              } else if (status == 'cancelled' ||
                  status == 'rejected' ||
                  status == 'refused') {
                badgeColor = context.colors.error;
                statusLabel = 'Imeghairiwa';
              }

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: context.colors.outlineVariant),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // Navigate directly to the live tracking / detail screen for this order
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConsumerOrderScreen(
                          orderId: orderId,
                          vendorId:
                              (data['vendor_id'] ?? data['vendorId'] ?? '')
                                  .toString(),
                          vendorName: (data['vendor_name'] ??
                                  data['vendorName'] ??
                                  'Gas Vendor')
                              .toString(),
                          brandName: brand,
                          cylinderSize: size,
                          unitPrice:
                              (data['unit_price'] as num?)?.toDouble() ?? 0.0,
                          totalPrice: total.toDouble(),
                          deliveryAddress: (data['delivery_address'] ??
                                  data['deliveryAddress'] ??
                                  '')
                              .toString(),
                          contactPhone: (data['contact_phone'] ??
                                  data['consumerPhone'] ??
                                  '')
                              .toString(),
                          paymentMethod:
                              (data['payment_method'] ?? 'cash').toString(),
                          quantity: (data['quantity'] as num?)?.toInt() ?? 1,
                          specialRequests:
                              (data['special_requests'] ?? '').toString(),
                          receiverPhone:
                              (data['receiver_phone'] ?? '').toString(),
                          orderIntent: intent,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.colors.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.propane_tank,
                              color: context.colors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$brand ($size)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: context.colors.onSurface),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(
                                          color: badgeColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'TZS ${total.toStringAsFixed(0)} • ${intent == 'add_stock' ? '🔄 Ongeza Akiba' : '📦 Mtungi Mpya'}',
                                style: TextStyle(
                                    fontSize: 11, color: context.colors.onSurfaceVariant),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tarehe: ${createdAt.toLocal().toString().split('.').first}',
                                style: TextStyle(
                                    fontSize: 10, color: context.colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right,
                            color: context.colors.onSurfaceVariant, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
