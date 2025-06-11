// lib/plugins/crm/screens/contacts_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/contact_provider.dart';
import '../models/contact.dart';
import 'contact_detail_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ContactProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        // supprime le bouton « précédent » automatique
        automaticallyImplyLeading: false,
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : prov.contacts.isEmpty
          ? const Center(child: Text('Aucun contact trouvé'))
          : ListView.builder(
        itemCount: prov.contacts.length,
        itemBuilder: (ctx, i) {
          final Contact c = prov.contacts[i];
          return ListTile(
            title: Text(c.name),
            subtitle: Text(c.email),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                if (c.id != null) {
                  await prov.delete(c.id!);
                }
              },
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ContactDetailScreen(contactId: c.id!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
