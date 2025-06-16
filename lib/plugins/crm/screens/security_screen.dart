// lib/plugins/crm/screens/security_screen.dart

import 'package:flutter/material.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sécurité')),
      body: Center(
        child: Text(
          'Paramètres de sécurité à implémenter',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}