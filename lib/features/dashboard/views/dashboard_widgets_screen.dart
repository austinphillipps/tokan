import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/dashboard_widget_provider.dart';
import '../../../core/providers/plugin_provider.dart';

/// Écran listant tous les widgets disponibles pour le dashboard et
/// permettant de les activer ou désactiver.
class DashboardWidgetsScreen extends StatelessWidget {
  const DashboardWidgetsScreen({Key? key}) : super(key: key);

  static const String projectWidgetId = 'projectProgress';

  @override
  Widget build(BuildContext context) {
    final dashboardProv = context.watch<DashboardWidgetProvider>();
    final pluginProv = context.watch<PluginProvider>();

    final items = <_DashboardItem>[
      _DashboardItem(
        id: projectWidgetId,
        label: 'Suivi projets',
      ),
      for (final p in pluginProv.installedPlugins)
        if (p.buildDashboardWidget(context) != null)
          _DashboardItem(id: p.id, label: p.displayName),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Widgets du dashboard')),
      body: ListView(
        children: [
          for (final item in items)
            SwitchListTile(
              title: Text(item.label),
              value: dashboardProv.isEnabled(item.id),
              onChanged: (_) => dashboardProv.toggle(item.id),
            ),
        ],
      ),
    );
  }
}

class _DashboardItem {
  final String id;
  final String label;
  _DashboardItem({required this.id, required this.label});
}