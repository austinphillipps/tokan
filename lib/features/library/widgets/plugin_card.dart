import 'package:flutter/material.dart';
import 'package:tokan/core/contract/plugin_contract.dart';

/// Display a single plugin as a card in the library grid.

class PluginCard extends StatelessWidget {
  final PluginContract plugin;
  final bool installed;
  final VoidCallback onInstall;
  final VoidCallback onUninstall;

  const PluginCard({
    Key? key,
    required this.plugin,
    required this.installed,
    required this.onInstall,
    required this.onUninstall,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(plugin.iconData, size: 40),
            const SizedBox(height: 8),
            Text(
              plugin.displayName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: installed ? onUninstall : onInstall,
              child: Text(installed ? 'Désinstaller' : 'Installer'),
            ),
          ],
        ),
      ),
    );
  }
}
