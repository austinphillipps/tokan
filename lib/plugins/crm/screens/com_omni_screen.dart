// lib/plugins/crm/screens/com_omni_screen.dart

import 'package:flutter/material.dart';

class ComOmniScreen extends StatelessWidget {
  const ComOmniScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Com. Omni.')),
      body: Center(
        child: Text(
          'Communication Omnicanale à implémenter',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
