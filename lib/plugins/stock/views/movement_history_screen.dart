// lib/plugins/stock/views/movement_history_screen.dart

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/stock_movement.dart';
import '../services/stock_service.dart';

class MovementHistoryScreen extends StatelessWidget {
  final Product product;

  const MovementHistoryScreen({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stockService = StockService();

    return Scaffold(
      appBar: AppBar(title: Text('Historique : ${product.name}')),
      body: FutureBuilder<List<StockMovement>>(
        future: stockService.fetchAllMovements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final allMovements = snapshot.data ?? [];
          final movements = allMovements
              .where((m) => m.productId == product.id)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          if (movements.isEmpty) {
            return const Center(child: Text('Aucun mouvement pour ce produit.'));
          }

          return ListView.separated(
            itemCount: movements.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final m = movements[index];
              final typeLabel = m.type == StockMovementType.IN ? 'Entrée' : 'Sortie';
              final color = m.type == StockMovementType.IN ? Colors.green : Colors.red;
              final icon = m.type == StockMovementType.IN
                  ? Icons.arrow_downward
                  : Icons.arrow_upward;

              return ListTile(
                leading: Icon(icon, color: color),
                title: Text('$typeLabel : ${m.quantity}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (m.reference.isNotEmpty) Text('Réf : ${m.reference}'),
                    if (m.reason.isNotEmpty) Text('Motif : ${m.reason}'),
                    Text('Date : ${m.date.day}/${m.date.month}/${m.date.year}'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
