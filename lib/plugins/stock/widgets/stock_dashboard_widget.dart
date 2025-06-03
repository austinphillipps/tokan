// lib/plugins/stock/widgets/stock_dashboard_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider.dart';

class StockDashboardWidget extends StatefulWidget {
  const StockDashboardWidget({Key? key}) : super(key: key);

  @override
  State<StockDashboardWidget> createState() => _StockDashboardWidgetState();
}

class _StockDashboardWidgetState extends State<StockDashboardWidget> {
  bool _isLoadingValue = false;
  double _totalValue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTotalValue();
  }

  Future<void> _loadTotalValue() async {
    setState(() => _isLoadingValue = true);
    final val = await context.read<StockProvider>().recalcStockValue();
    setState(() {
      _totalValue = val;
      _isLoadingValue = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stockProv = context.watch<StockProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aperçu Stock',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _StatCard(
              label: 'Articles',
              value: stockProv.totalItems.toString(),
              icon: Icons.inventory_2,
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Sous seuil',
              value: stockProv.lowStockCount.toString(),
              icon: Icons.warning_amber_rounded,
              color: Colors.orange.shade200,
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Ruptures',
              value: stockProv.outOfStockCount.toString(),
              icon: Icons.error_outline,
              color: Colors.red.shade200,
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Valeur totale',
              value: _isLoadingValue ? '…' : '${_totalValue.toStringAsFixed(2)} €',
              icon: Icons.attach_money,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Placeholder pour futur graphique d’évolution
        Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(child: Text('Graphique évolution (à venir)')),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatCard({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color ?? Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
