import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/role_router.dart';

class GasLinkApp extends StatelessWidget {
  const GasLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GasLink',
      theme: buildAppTheme(),
      home: const RoleRouter(),
    );
  }
}
