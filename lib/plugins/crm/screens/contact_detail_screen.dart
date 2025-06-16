// lib/plugins/crm/screens/contact_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/contact_provider.dart';
import '../models/contact.dart';
import 'contact_form_screen.dart';  // ← import du formulaire

class ContactDetailScreen extends StatefulWidget {
  final String contactId;
  const ContactDetailScreen({Key? key, required this.contactId}) : super(key: key);

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  Contact? _contact;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContact();
  }

  Future<void> _loadContact() async {
    final c = await context.read<ContactProvider>().fetchById(widget.contactId);
    setState(() {
      _contact = c;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du contact'),
        actions: [
          if (!_loading && _contact != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // ← on ouvre l'écran d'édition avec MaterialPageRoute
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ContactFormScreen(contactId: widget.contactId),
                  ),
                );
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _contact == null
          ? const Center(child: Text('Contact introuvable'))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prénom : ${_contact!.firstName}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Nom : ${_contact!.name}'),
            const SizedBox(height: 8),
            Text('Email : ${_contact!.email}'),
            if (_contact!.phone != null && _contact!.phone!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Téléphone : ${_contact!.phone}'),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text('Supprimer ce contact'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                await context.read<ContactProvider>().delete(widget.contactId);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}