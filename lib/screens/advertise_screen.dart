// lib/screens/advertise_screen.dart
// "Tangaza na GasLink": pitch + request form for gas stakeholders who want to
// run campaigns in the app. Submissions write to ad_requests in Firestore.

import 'package:flutter/material.dart';

import '../core/theme_ext.dart';
import '../services/ad_service.dart';
import '../widgets/app_ui.dart';

class AdvertiseScreen extends StatefulWidget {
  const AdvertiseScreen({super.key});

  @override
  State<AdvertiseScreen> createState() => _AdvertiseScreenState();
}

class _AdvertiseScreenState extends State<AdvertiseScreen> {
  final _company = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();
  final _budget = TextEditingController();
  String _audience = 'consumer';
  String _placement = 'consumer_home';
  bool _submitting = false;

  static const _placements = [
    ('consumer_home', 'Consumer home banner'),
    ('vendor_list', 'Vendor search results'),
    ('vendor_dashboard', 'Vendor dashboard (B2B)'),
    ('order_success', 'Order success footer'),
  ];

  @override
  void dispose() {
    _company.dispose();
    _phone.dispose();
    _message.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_company.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Jaza jina la kampuni na namba ya simu / Fill company and phone.'),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await AdService.instance.submitAdRequest(
        company: _company.text,
        contactPhone: _phone.text,
        audience: _audience,
        placement: _placement,
        message: _message.text,
        budget: _budget.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Ombi limepokelewa! Tutawasiliana nawe hivi karibuni.'),
          backgroundColor: context.gasColors.success,
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imeshindikana kutuma ombi: $error'),
          backgroundColor: context.colors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Tangaza na GasLink',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppSectionHeader(
            title: 'Fikia wateja wako wa gesi',
            subtitle:
                'Matangazo yasiyo ya kusumbua kwa wateja, wauzaji au wote.',
            icon: Icons.campaign_outlined,
          ),
          const SizedBox(height: 12),
          const AppCard(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kwa nini utangaze nasi?',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text(
                  '• Wateja wanaotafuta gesi kila siku\n'
                  '• Wauzaji wa reja reja kwa matangazo ya B2B\n'
                  '• Nafasi za banner, si popups za kusumbua',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const AppSectionHeader(
            title: 'Tuma ombi / Send a request',
            icon: Icons.edit_outlined,
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                TextField(
                  controller: _company,
                  decoration: const InputDecoration(
                    labelText: 'Jina la Kampuni / Company',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Namba ya Simu / Contact phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _audience,
                  decoration: const InputDecoration(
                    labelText: 'Watazamaji / Audience',
                    prefixIcon: Icon(Icons.groups_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'consumer', child: Text('Wateja / Consumers')),
                    DropdownMenuItem(
                        value: 'vendor',
                        child: Text('Wauzaji / Vendors (B2B)')),
                    DropdownMenuItem(value: 'both', child: Text('Wote / Both')),
                  ],
                  onChanged: (value) =>
                      setState(() => _audience = value ?? 'consumer'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _placement,
                  decoration: const InputDecoration(
                    labelText: 'Mahali / Placement',
                    prefixIcon: Icon(Icons.pin_drop_outlined),
                  ),
                  items: [
                    for (final (value, label) in _placements)
                      DropdownMenuItem(value: value, child: Text(label)),
                  ],
                  onChanged: (value) =>
                      setState(() => _placement = value ?? 'consumer_home'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _message,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Ujumbe / Message (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _budget,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Bajeti / Budget TZS (optional)',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(
                      _submitting ? 'Inatuma…' : 'Tuma Ombi / Send request',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
