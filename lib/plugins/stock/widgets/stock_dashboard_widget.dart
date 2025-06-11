// lib/plugins/stock/widgets/stock_dashboard_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../main.dart'; // Pour accéder à AppColors, themeNotifier et AppTheme
import '../providers/stock_provider.dart';

class StockDashboardWidget extends StatefulWidget {
  const StockDashboardWidget({Key? key}) : super(key: key);

  @override
  State<StockDashboardWidget> createState() => _StockDashboardWidgetState();
}

class _StockDashboardWidgetState extends State<StockDashboardWidget> {
  @override
  Widget build(BuildContext context) {
    final stockProv = Provider.of<StockProvider>(context);
    final bool isSequoia = themeNotifier.value == AppTheme.sequoia;

    // Fond global du widget : verre sombre
    final Color background = AppColors.glassBackground;

    return Container(
      color: background,
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête « Aperçu Stock » avec verre sombre un peu plus opaque
          Container(
            width: double.infinity,
            color: AppColors.glassHeader,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: const Text(
              'APERÇU STOCK',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Statistiques en cartes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Articles\n(total)',
                  value: stockProv.totalItems.toString(),
                  icon: Icons.inventory_2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Sous seuil',
                  value: stockProv.lowStockCount.toString(),
                  icon: Icons.warning_amber_rounded,
                  color: Colors.amberAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Ruptures',
                  value: stockProv.outOfStockCount.toString(),
                  icon: Icons.error_outline,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Exemple de graphique ou liste (placeholder)
          Expanded(
            child: Center(
              child: Text(
                'Graphique / Détails Stocks…',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),
          ),
        ],
      ),
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
    // Fond de chaque carte : verre sombre (un peu moins opaque que glassHeader)
    final Color cardBg = AppColors.glassBackground;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 28,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
