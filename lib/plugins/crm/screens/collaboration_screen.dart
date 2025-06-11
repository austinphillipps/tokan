// lib/plugins/crm/screens/collaboration_screen.dart

import 'package:flutter/material.dart';

class CollaborationScreen extends StatelessWidget {
  const CollaborationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collab.')),
      body: Center(
        child: Text(
          'Gestion des collaborateurs à implémenter',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
