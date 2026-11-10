import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme_ext.dart';
import '../../models/analytics.dart';
import '../../services/analytics_service.dart';
import '../../utils/csv_export_stub.dart'
    if (dart.library.html) '../../utils/csv_export_web.dart' as csv_export;
import '../../utils/formatters.dart';
import 'widgets/admin_ui.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  int _days = 30;
  late Future<AnalyticsSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = AnalyticsService.instance.load(days: _days);
  }

  Future<void> _load() async {
    final future = AnalyticsService.instance.load(days: _days);
    setState(() => _future = future);
    await future;
  }

  Future<void> _export(AnalyticsSnapshot snapshot) async {
    try {
      final csv = AnalyticsCsv.build(snapshot);
      final stamp = DateTime.now().toIso8601String().substring(0, 10);
      final message = await csv_export.exportCsv(
        filename: 'gaslink-analytics-${_days}d-$stamp.csv',
        csv: csv,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: context.gasColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not export CSV: $error'),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: FutureBuilder<AnalyticsSnapshot>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AdminLoading();
          }
          if (snapshot.hasError) {
            return ListView(
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.6,
                  child: AdminErrorState(
                    message: '${snapshot.error}',
                    onRetry: _load,
                  ),
                ),
              ],
            );
          }

          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Operational analytics',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${formatDate(data.from)} — ${formatDate(data.to)} · '
                          '${AnalyticsSnapshot.timezone}',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _export(data),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('CSV'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 7, label: Text('7 days')),
                  ButtonSegment(value: 30, label: Text('30 days')),
                  ButtonSegment(value: 90, label: Text('90 days')),
                ],
                selected: {_days},
                onSelectionChanged: (selection) {
                  final days = selection.first;
                  setState(() {
                    _days = days;
                    _future = AnalyticsService.instance.load(days: days);
                  });
                },
              ),
              const SizedBox(height: 16),
              if (data.isEmpty)
                AdminCard(
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: context.gasColors.info),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'No orders in this range yet. KPIs will appear as soon as trading starts.',
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900
                        ? 4
                        : constraints.maxWidth >= 620
                            ? 3
                            : 2;
                    const gap = 10.0;
                    final width =
                        (constraints.maxWidth - (columns - 1) * gap) / columns;
                    final cards = [
                      AdminStatCard(
                        label: 'GMV',
                        value: formatTzs(data.gmv, compact: true),
                        subtitle: 'Delivered only',
                        icon: Icons.payments_outlined,
                        accent: context.gasColors.success,
                      ),
                      AdminStatCard(
                        label: 'Orders',
                        value: formatNumber(data.totalOrders),
                        subtitle: '${data.deliveredOrders} delivered',
                        icon: Icons.receipt_long_outlined,
                        accent: context.gasColors.info,
                      ),
                      AdminStatCard(
                        label: 'Avg order value',
                        value: formatTzs(data.aov, compact: true),
                        icon: Icons.shopping_bag_outlined,
                      ),
                      AdminStatCard(
                        label: 'Completion rate',
                        value: formatPercent(data.completionRate),
                        icon: Icons.task_alt,
                        accent: context.gasColors.success,
                      ),
                      AdminStatCard(
                        label: 'Cancellation rate',
                        value: formatPercent(data.cancellationRate),
                        icon: Icons.cancel_outlined,
                        accent: context.colors.error,
                      ),
                      AdminStatCard(
                        label: 'Avg delivery',
                        value: formatDurationMinutes(data.avgDeliveryMinutes),
                        icon: Icons.local_shipping_outlined,
                        accent: context.gasColors.info,
                      ),
                      AdminStatCard(
                        label: 'Repeat rate',
                        value: formatPercent(data.repeatRate),
                        subtitle: '${data.repeatConsumers} repeat buyers',
                        icon: Icons.repeat,
                      ),
                      AdminStatCard(
                        label: 'Delivered consumers',
                        value: formatNumber(data.uniqueConsumers),
                        icon: Icons.people_alt_outlined,
                        accent: context.gasColors.info,
                      ),
                    ];
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final card in cards)
                          SizedBox(width: width, child: card),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                const AdminSectionHeader(
                  title: 'Order trend',
                  subtitle: 'Daily order volume in the reporting timezone.',
                ),
                _TrendCard(data: data),
                const SizedBox(height: 22),
                const AdminSectionHeader(
                  title: 'Status breakdown',
                  subtitle: 'Where orders currently sit in the lifecycle.',
                ),
                AdminCard(
                  child: Column(
                    children: [
                      for (final status in data.statusBreakdown)
                        if (status.count > 0)
                          _BreakdownRow(
                            label: status.status.replaceAll('_', ' '),
                            count: status.count,
                            total: data.totalOrders,
                            color: adminStatusColor(context, status.status),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const AdminSectionHeader(
                  title: 'Top vendors by GMV',
                  subtitle: 'Delivered value in this range.',
                ),
                if (data.topVendors.isEmpty)
                  const AdminCard(child: Text('No vendor performance yet.'))
                else
                  AdminCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < data.topVendors.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          ListTile(
                            leading: AdminAvatar(
                              name: data.topVendors[i].name,
                            ),
                            title: Text(
                              data.topVendors[i].name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${data.topVendors[i].district} · '
                              '${data.topVendors[i].orders} orders · '
                              'fill ${formatPercent(data.topVendors[i].fillRate)}',
                            ),
                            trailing: Text(
                              formatTzs(data.topVendors[i].gmv, compact: true),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 22),
                _DemandSection(
                  title: 'Demand by brand',
                  subtitle: 'Order mix across stocked brands.',
                  items: data.brandDemand,
                  total: data.totalOrders,
                ),
                const SizedBox(height: 22),
                _DemandSection(
                  title: 'Demand by size',
                  subtitle: 'Cylinder size popularity.',
                  items: data.sizeDemand,
                  total: data.totalOrders,
                  accent: context.gasColors.info,
                ),
                const SizedBox(height: 22),
                const AdminSectionHeader(
                  title: 'District performance',
                  subtitle: 'Orders and delivered value by vendor district.',
                ),
                AdminCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0;
                          i < data.districtPerformance.length;
                          i++) ...[
                        if (i > 0) const Divider(height: 1),
                        ListTile(
                          dense: true,
                          leading: Icon(Icons.location_city_outlined,
                              color: context.colors.primary),
                          title: Text(
                            data.districtPerformance[i].district,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${data.districtPerformance[i].delivered} delivered '
                            'of ${data.districtPerformance[i].orders}',
                          ),
                          trailing: Text(
                            formatTzs(
                              data.districtPerformance[i].gmv,
                              compact: true,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const AdminSectionHeader(
                  title: 'Vendor scorecards',
                  subtitle: 'Volume, fill rate and delivery speed.',
                ),
                AdminCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0;
                          i < data.vendorScorecards.length;
                          i++) ...[
                        if (i > 0) const Divider(height: 1),
                        ListTile(
                          dense: true,
                          title: Text(
                            data.vendorScorecards[i].name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${data.vendorScorecards[i].orders} orders · '
                            'fill ${formatPercent(data.vendorScorecards[i].fillRate)} · '
                            '${formatDurationMinutes(data.vendorScorecards[i].avgDeliveryMinutes)}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatTzs(data.vendorScorecards[i].gmv,
                                    compact: true),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${data.vendorScorecards[i].cancelled} cancelled',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              AdminCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: context.gasColors.info),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Metric definitions: GMV uses delivered totals; AOV = '
                        'GMV ÷ delivered orders; completion = delivered ÷ '
                        '(delivered + cancelled); repeat rate counts consumers '
                        'with 2+ deliveries. Currency TZS, timezone '
                        '${AnalyticsSnapshot.timezone}.',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.data});

  final AnalyticsSnapshot data;

  @override
  Widget build(BuildContext context) {
    final maxOrders = data.dailyTrend.fold<int>(
      0,
      (max, point) => math.max(max, point.orders),
    );
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${data.totalOrders} orders',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                'Peak ${maxOrders == 0 ? '—' : maxOrders}',
                style: TextStyle(
                  fontSize: 11,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            label: 'Daily order trend chart. Peak $maxOrders orders.',
            child: SizedBox(
              height: 150,
              width: double.infinity,
              child: CustomPaint(
                painter: _TrendPainter(
                  points: data.dailyTrend,
                  barColor: context.colors.primary,
                  gridColor: context.colors.outlineVariant,
                  emptyColor: context.colors.outlineVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                data.dailyTrend.isEmpty
                    ? '—'
                    : formatDate(data.dailyTrend.first.date),
                style: TextStyle(
                  fontSize: 10,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                data.dailyTrend.isEmpty
                    ? '—'
                    : formatDate(data.dailyTrend.last.date),
                style: TextStyle(
                  fontSize: 10,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.points,
    required this.barColor,
    required this.gridColor,
    required this.emptyColor,
  });

  final List<DailyOrderPoint> points;
  final Color barColor;
  final Color gridColor;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    if (points.isEmpty) return;

    final maxValue = points.fold<int>(
      1,
      (max, point) => math.max(max, point.orders),
    );
    final slot = size.width / points.length;
    final barWidth = math.max(2.0, slot * 0.55);
    final paint = Paint()..color = barColor;

    for (var i = 0; i < points.length; i++) {
      final value = points[i].orders;
      final height = value == 0 ? 2.0 : (value / maxValue) * size.height;
      final left = i * slot + (slot - barWidth) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, size.height - height, barWidth, height),
        const Radius.circular(3),
      );
      paint.color = value == 0 ? emptyColor : barColor;
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.barColor != barColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.emptyColor != emptyColor;
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label[0].toUpperCase() + label.substring(1),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$count · ${formatPercent(fraction)}',
                style: TextStyle(
                  fontSize: 11,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: fraction,
              backgroundColor: context.colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemandSection extends StatelessWidget {
  const _DemandSection({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.total,
    this.accent,
  });

  final String title;
  final String subtitle;
  final List<DemandCount> items;
  final int total;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return AdminSectionHeader(title: title, subtitle: subtitle);
    }
    final maxCount = items.fold<int>(
      1,
      (max, item) => math.max(max, item.count),
    );
    final color = accent ?? context.colors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionHeader(title: title, subtitle: subtitle),
        AdminCard(
          child: Column(
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 82,
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: item.count / maxCount,
                            backgroundColor:
                                context.colors.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 52,
                        child: Text(
                          '${item.count} · '
                          '${total == 0 ? '0%' : formatPercent(item.count / total)}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 10,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
