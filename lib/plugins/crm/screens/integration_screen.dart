// lib/plugins/crm/screens/integration_screen.dart

import 'package:flutter/material.dart';

class IntegrationScreen extends StatelessWidget {
  const IntegrationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Intégrations')),
      body: Center(
        child: Text(
          'Gestion des intégrations à implémenter',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
