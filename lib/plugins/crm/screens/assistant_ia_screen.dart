// lib/plugins/crm/screens/assistant_ia_screen.dart

import 'package:flutter/material.dart';

class AssistantIaScreen extends StatelessWidget {
  const AssistantIaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant IA')),
      body: Center(
        child: Text(
          'Assistant IA à implémenter',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
