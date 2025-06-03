// lib/core/plugin_registry.dart

import 'package:flutter/material.dart';
import 'plugin_contract.dart';

// Import du plugin Hazel
import '../../plugins/stock/services/stock_plugin.dart';

// (Plus tard, tu ajouteras d’autres plugins ici)

final List<PluginContract> allPlugins = [
  StockPlugin(),
  // Ajoute d’autres instances de PluginContract selon les prochains plugins
];

PluginContract? getPluginById(String id) {
  for (final p in allPlugins) {
    if (p.id == id) return p;
  }
  return null;
}
