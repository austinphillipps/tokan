// lib/plugins/stock/views/supplier_list_screen.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/supplier.dart';
import '../services/stock_service.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({Key? key}) : super(key: key);

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final StockService _service = StockService();
  bool _isLoading = false;
  List<Supplier> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);
    try {
      final fetched = await _service.fetchAllSuppliers();
      fetched.sort((a, b) => a.name.compareTo(b.name));
      setState(() {
        _suppliers = fetched;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement : $e')),
      );
    }
  }

  Future<void> _showSupplierDialog({Supplier? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final contactCtrl = TextEditingController(text: existing?.contactDetails ?? '');
    final leadTimeCtrl = TextEditingController(text: existing?.leadTime.toString() ?? '0');
    final paymentTermsCtrl = TextEditingController(text: existing?.paymentTerms ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    final isNew = existing == null;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isNew ? 'Nouveau fournisseur' : 'Modifier le fournisseur'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: contactCtrl,
                decoration: const InputDecoration(labelText: 'Coordonnées'),
              ),
              TextField(
                controller: leadTimeCtrl,
                decoration: const InputDecoration(labelText: 'Délai (jours)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: paymentTermsCtrl,
                decoration: const InputDecoration(labelText: 'Conditions de paiement'),
              ),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final contact = contactCtrl.text.trim();
              final leadTime = int.tryParse(leadTimeCtrl.text.trim()) ?? 0;
              final terms = paymentTermsCtrl.text.trim();
              final notes = notesCtrl.text.trim();

              if (name.isEmpty) return;

              try {
                if (isNew) {
                  final newSupplier = Supplier(
                    id: const Uuid().v4(),
                    name: name,
                    contactDetails: contact,
                    leadTime: leadTime,
                    paymentTerms: terms,
                    notes: notes,
                  );
                  await _service.addSupplier(newSupplier);
                } else {
                  existing!.name = name;
                  existing.contactDetails = contact;
                  existing.leadTime = leadTime;
                  existing.paymentTerms = terms;
                  existing.notes = notes;
                  await _service.updateSupplier(existing);
                }

                if (context.mounted) Navigator.pop(context);
                _loadSuppliers();
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur : $e')),
                  );
                }
              }
            },
            child: Text(isNew ? 'Ajouter' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteSupplier(Supplier supplier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer le fournisseur "${supplier.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteSupplier(supplier.id);
        _loadSuppliers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fournisseurs')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _suppliers.isEmpty
          ? const Center(child: Text('Aucun fournisseur enregistré.'))
          : ListView.separated(
        itemCount: _suppliers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final s = _suppliers[index];
          return ListTile(
            title: Text(s.name),
            subtitle: Text('Délai: ${s.leadTime} j — ${s.contactDetails}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showSupplierDialog(existing: s),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDeleteSupplier(s),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSupplierDialog(),
        tooltip: 'Ajouter un fournisseur',
        child: const Icon(Icons.add),
      ),
    );
  }
}
