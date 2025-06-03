import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/product.dart';
import '../models/inventory_count.dart';
import '../providers/stock_provider.dart';

class InventoryCountScreen extends StatefulWidget {
  const InventoryCountScreen({Key? key}) : super(key: key);

  @override
  State<InventoryCountScreen> createState() => _InventoryCountScreenState();
}

class _InventoryCountScreenState extends State<InventoryCountScreen> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stockProv = context.watch<StockProvider>();
    final products = stockProv.products;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaire physique'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Valider inventaire',
            onPressed: () async {
              final lines = <InventoryLine>[];
              for (final p in products) {
                final text = _controllers[p.id]?.text.trim() ?? '';
                final countedQty = int.tryParse(text);
                if (countedQty != null) {
                  lines.add(InventoryLine(
                    productId: p.id,
                    countedQuantity: countedQty,
                  ));
                }
              }

              final count = InventoryCount(
                id: const Uuid().v4(),
                date: DateTime.now(),
                locationId: 'default',
                performedBy: 'admin',
                lines: lines,
              );

              await context.read<StockProvider>().addInventoryCount(count);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Inventaire enregistré.')),
                );
                Navigator.pop(context);
              }
            },
          )
        ],
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          final ctrl = _controllers.putIfAbsent(
            p.id,
                () => TextEditingController(text: p.quantityInStock.toString()),
          );

          return ListTile(
            title: Text(p.name),
            subtitle: Text('Stock théorique : ${p.quantityInStock}'),
            trailing: SizedBox(
              width: 80,
              child: TextField(
                controller: ctrl,
                decoration: const InputDecoration(labelText: 'Compté'),
                keyboardType: TextInputType.number,
              ),
            ),
          );
        },
      ),
    );
  }
}
