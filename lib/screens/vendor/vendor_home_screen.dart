import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class VendorHomeScreen extends StatelessWidget {
  const VendorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final phone = AuthService.instance.currentPhone;
    return Scaffold(
      appBar: AppBar(
        title: const Text('GasLink — Vendor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Center(child: Text('Vendor logged in as ${phone ?? 'unknown'}')),
      // Tomorrow: real-time order inbox replaces this
    );
  }
}
