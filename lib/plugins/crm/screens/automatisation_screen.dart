// lib/plugins/crm/screens/automatisation_screen.dart

import 'package:flutter/material.dart';

class AutomatisationScreen extends StatelessWidget {
  const AutomatisationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Automatisation')),
      body: Center(
        child: Text(
          'Contenu Automatisation à implémenter',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
