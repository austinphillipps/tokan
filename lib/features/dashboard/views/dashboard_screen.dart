import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tokan/core/providers/plugin_provider.dart';
import 'package:tokan/core/contract/plugin_contract.dart';
import '../widgets/project_progress_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pluginProv = context.watch<PluginProvider>();
    final installedPlugins = pluginProv.installedPlugins;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tableau de bord principal', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          const ProjectProgressWidget(),
          const SizedBox(height: 16),

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
