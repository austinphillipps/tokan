// lib/plugins/crm/screens/dashboard_ai_screen.dart

import 'package:flutter/material.dart';

class DashboardAiScreen extends StatelessWidget {
  const DashboardAiScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard AI')),
      body: Center(
        child: Text(
          'Contenu du Dashboard AI à implémenter',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
