import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/plugin_provider.dart';
import '../../main.dart';

/// Screen allowing to enable or disable dashboard widgets for installed plugins.
class WidgetSettingsScreen extends StatelessWidget {
  const WidgetSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pluginProv = context.watch<PluginProvider>();
    final plugins = pluginProv.installedPlugins;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkGreyBackground,
        foregroundColor: Colors.white,
        title: const Text('Widgets du dashboard'),
      ),
      body: ListView(
        children: plugins
            .map((plugin) => SwitchListTile(
          title: Text(plugin.displayName,
              style: const TextStyle(color: Colors.white)),
          secondary: Icon(plugin.iconData, color: Colors.white),
          activeColor: AppColors.green,
          value: pluginProv.isWidgetEnabled(plugin.id),
          onChanged: (_) => pluginProv.toggleWidget(plugin.id),
        ))
            .toList(),
      ),
    );
  }
}