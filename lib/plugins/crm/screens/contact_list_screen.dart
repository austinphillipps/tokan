// lib/plugins/crm/screens/contact_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tokan/main.dart'; // pour AppColors
import '../providers/contact_provider.dart';
import '../models/contact.dart';
import 'contact_detail_screen.dart';
import 'contact_form_screen.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({Key? key}) : super(key: key);

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  bool _showPanel = false;
  String? _panelContactId;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Ouvre le panneau (form si [contactId]==null, sinon détail)
  void _openPanel({String? contactId}) {
    setState(() {
      _panelContactId = contactId;
      _showPanel = true;
    });
  }

  /// Ferme le panneau
  void _closePanel() {
    setState(() {
      _showPanel = false;
      _panelContactId = null;
    });
  }

  /// Affiche une boîte de dialogue pour rechercher un contact par son nom
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setState) {
            final contacts = context
                .read<ContactProvider>()
                .contacts
                .where((c) =>
                ('${c.firstName} ${c.name}').toLowerCase().contains(query))
                .toList();

            return AlertDialog(
              title: const Text('Rechercher un contact'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Nom du contact',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (val) =>
                          setState(() => query = val.toLowerCase()),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: contacts.isEmpty
                          ? const Center(child: Text('Aucun résultat'))
                          : ListView.builder(
                        itemCount: contacts.length,
                        itemBuilder: (ctx, i) {
                          final c = contacts[i];
                          return ListTile(
                            title: Text(c.name),
                            onTap: () {
                              Navigator.of(dialogCtx).pop();
                              _openPanel(contactId: c.id);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Fermer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Charge la liste au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ContactProvider>();
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        automaticallyImplyLeading: false,
        leading: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1) La liste des contacts
          if (prov.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (prov.contacts.isEmpty)
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _openPanel(contactId: null),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter votre premier contact'),
              ),
            )
          else
            ListView.builder(
              itemCount: prov.contacts.length,
              itemBuilder: (ctx, i) {
                final Contact c = prov.contacts[i];
                return ListTile(
                  title: Text('${c.firstName} ${c.name}'),
                  subtitle: Text(c.email),
                  onTap: () => _openPanel(contactId: c.id),
                );
              },
            ),

          // 2) Overlay pour fermer au clic hors du panneau
          if (_showPanel)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closePanel,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.black26),
              ),
            ),

          // 3) Le panneau latéral glissant
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            top: 0,
            bottom: 0,
            right: _showPanel ? 0 : -screenWidth * 0.75,
            width: screenWidth * 0.25,
            child: Material(
              elevation: 16,
              color: AppColors.glassBackground,
              child: SafeArea(
                child: _panelContactId == null
                    ? ContactFormScreen(onSaved: _closePanel)
                    : ContactDetailScreen(contactId: _panelContactId!),
              ),
            ),
          ),
        ],
      ),

      // On cache le FAB lorsque le panneau est ouvert
      floatingActionButton: !_showPanel
          ? FloatingActionButton(
        tooltip: 'Nouveau contact',
        child: const Icon(Icons.add),
        onPressed: () => _openPanel(contactId: null),
      )
          : null,
    );
  }
}