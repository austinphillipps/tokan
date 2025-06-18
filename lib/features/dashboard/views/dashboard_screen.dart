import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tokan/core/providers/plugin_provider.dart';
import 'package:tokan/core/providers/dashboard_widget_provider.dart';
import 'package:tokan/core/contract/plugin_contract.dart';
import 'dashboard_widgets_screen.dart';
import '../widgets/project_progress_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pluginProv = context.watch<PluginProvider>();
    final dashboardProv = context.watch<DashboardWidgetProvider>();
    final installedPlugins = pluginProv.installedPlugins;

    dashboardProv.ensureDefaults([
      DashboardWidgetsScreen.projectWidgetId,
      for (final p in installedPlugins) p.id,
    ]);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Tableau de bord principal',
                    style: theme.textTheme.titleLarge),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Configurer les widgets',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const DashboardWidgetsScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (dashboardProv
              .isEnabled(DashboardWidgetsScreen.projectWidgetId))
            const ProjectProgressWidget(),

          if (installedPlugins.isNotEmpty) ...[
            const Divider(height: 32),
            Text('Extensions installées', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final p in installedPlugins)
              if (p.buildDashboardWidget(context) != null &&
                  dashboardProv.isEnabled(p.id))
                p.buildDashboardWidget(context)!,
          ],
        ],
      ),
    );
  }
}
