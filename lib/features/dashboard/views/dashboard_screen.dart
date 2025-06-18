import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tokan/core/providers/plugin_provider.dart';
import 'package:tokan/core/contract/plugin_contract.dart';
import '../providers/dashboard_widget_provider.dart';
import 'manage_dashboard_widgets_sheet.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pluginProv = context.watch<PluginProvider>();
    final installedPlugins = pluginProv.installedPlugins;
    final dashboardProv = context.watch<DashboardWidgetProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tableau de bord principal', style: theme.textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.widgets),
                tooltip: 'Gérer les widgets',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => const ManageDashboardWidgetsSheet(),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // … vos autres widgets dashboard …

          for (final w in dashboardProv.widgets) w,

          if (installedPlugins.isNotEmpty) ...[
            const Divider(height: 32),
            Text('Extensions installées', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final p in installedPlugins)
              if (p.buildDashboardWidget(context) != null)
                p.buildDashboardWidget(context)!,
          ],
        ],
      ),
    );
  }
}
