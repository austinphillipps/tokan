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
            onPressed: () {
              // TODO: implémenter recherche
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1) La liste des contacts
          if (prov.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (prov.contacts.isEmpty)
            const Center(child: Text('Aucun contact trouvé'))
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
                    ? ContactFormScreen(onClose: _closePanel)
                    : ContactDetailScreen(contactId: _panelContactId!, onClose: _closePanel),
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
