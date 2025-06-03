// lib/plugins/stock/views/stock_movement_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/stock_movement.dart';
import '../models/product.dart';
import '../providers/stock_provider.dart';

class StockMovementDialog extends StatefulWidget {
  final Product product; // Le produit pour lequel on enregistre le mouvement

  const StockMovementDialog({Key? key, required this.product}) : super(key: key);

  @override
  State<StockMovementDialog> createState() => _StockMovementDialogState();
}

class _StockMovementDialogState extends State<StockMovementDialog> {
  late StockMovementType _selectedType;
  final TextEditingController _quantityCtrl = TextEditingController(text: '0');
  final TextEditingController _referenceCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedType = StockMovementType.IN; // Réception par défaut
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _referenceCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _selectedType == StockMovementType.IN
            ? 'Entrée de stock : ${widget.product.name}'
            : 'Sortie de stock : ${widget.product.name}',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Type IN / OUT
            Row(
              children: [
                Expanded(
                  child: RadioListTile<StockMovementType>(
                    title: const Text('Entrée'),
                    value: StockMovementType.IN,
                    groupValue: _selectedType,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<StockMovementType>(
                    title: const Text('Sortie'),
                    value: StockMovementType.OUT,
                    groupValue: _selectedType,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
                  ),
                ),
              ],
            ),

            // Quantité
            TextField(
              controller: _quantityCtrl,
              decoration: const InputDecoration(labelText: 'Quantité'),
              keyboardType: TextInputType.number,
            ),

            // Référence
            TextField(
              controller: _referenceCtrl,
              decoration: const InputDecoration(labelText: 'Référence (BL / facture)'),
            ),

            // Date
            Row(
              children: [
                const Text('Date :'),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  ),
                ),
              ],
            ),

            // Raison
            TextField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(labelText: 'Motif / commentaire'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            final qty = int.tryParse(_quantityCtrl.text.trim()) ?? 0;
            if (qty <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('La quantité doit être > 0')),
              );
              return;
            }

            final movement = StockMovement(
              id: const Uuid().v4(),
              productId: widget.product.id,
              type: _selectedType,
              quantity: qty,
              date: _selectedDate,
              reference: _referenceCtrl.text.trim(),
              reason: _reasonCtrl.text.trim(),
              notes: '',
              userId: 'user_dummy', // À remplacer par FirebaseAuth.currentUser!.uid
              locationFrom: null,
              locationTo: null,
            );

            await context.read<StockProvider>().addStockMovement(movement);

            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
