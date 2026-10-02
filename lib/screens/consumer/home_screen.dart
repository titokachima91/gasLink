import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ConsumerHomeScreen extends StatelessWidget {
  const ConsumerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final phone = AuthService.instance.currentPhone;
    return Scaffold(
      appBar: AppBar(title: const Text('GasLink — Consumer')),
      body: Center(child: Text('Logged in as ${phone ?? 'unknown'}')),
      // Tomorrow: vendor list replaces this
    );
  }
}
