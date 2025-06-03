// lib/plugins/stock/services/stock_plugin.dart

import 'package:flutter/material.dart';
import '../../../core/services/plugin_contract.dart';
import '../views/stock_screen.dart';
import '../widgets/stock_dashboard_widget.dart';

class StockPlugin implements PluginContract {
  @override
  String get id => 'stock'; // identifiant unique du plugin

  @override
  String get displayName => 'Stock';

  @override
  Widget get icon => const Icon(Icons.store_rounded, size: 28);

  @override
  Widget buildMainScreen(BuildContext context) {
    return const StockScreen();
  }

  @override
  Widget? buildDashboardWidget(BuildContext context) {
    return const StockDashboardWidget();
  }
}
