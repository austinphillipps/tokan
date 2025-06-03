import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory_count.dart';
import '../providers/stock_provider.dart';

class InventoryHistoryScreen extends StatelessWidget {
  const InventoryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stockProv = context.read<StockProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Historique des inventaires')),
      body: FutureBuilder(
        future: stockProv.fetchAllInventoryCounts(),
        builder: (context, snapshot) {
          final inventoryCounts = stockProv.inventoryCounts;
          if (inventoryCounts.isEmpty) {
            return const Center(child: Text('Aucun inventaire enregistré.'));
          }

          return ListView.builder(
            itemCount: inventoryCounts.length,
            itemBuilder: (context, index) {
              final inv = inventoryCounts[index];
              return ListTile(
                title: Text(
                  'Inventaire du ${inv.date.day}/${inv.date.month}/${inv.date.year}',
                ),
                subtitle: Text(
                  'Utilisateur: ${inv.performedBy} • Produits comptés: ${inv.lines.length}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
