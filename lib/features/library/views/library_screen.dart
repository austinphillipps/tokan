// lib/features/library/views/library_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tokan/core/providers/plugin_provider.dart';
import 'package:tokan/core/contract/plugin_contract.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({Key? key}) : super(key: key);
  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final pluginProv = context.watch<PluginProvider>();
    final all = pluginProv.registry.availablePlugins;
    final filtered = all.where((p) =>
        p.displayName.toLowerCase().contains(_search.toLowerCase())
    ).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    const spacing = 16.0;
    final gridWidth = screenWidth * 0.9;
    // 2 colonnes sur mobile, 4 sur écrans larges
    final columns = screenWidth < 600 ? 2 : 4;
    final cardWidth = (gridWidth - (columns - 1) * spacing) / columns;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Rechercher un plugin',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final p in filtered)
                    _PluginCard(
                      plugin: p,
                      installed: pluginProv.isInstalled(p.id),
                      width: cardWidth,
                      onInstall: () => pluginProv.install(p.id),
                      onUninstall: () => pluginProv.uninstall(p.id),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PluginCard extends StatelessWidget {
  final PluginContract plugin;
  final bool installed;
  final double width;
  final VoidCallback onInstall;
  final VoidCallback onUninstall;

  const _PluginCard({
    Key? key,
    required this.plugin,
    required this.installed,
    required this.width,
    required this.onInstall,
    required this.onUninstall,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(plugin.iconData, size: 40),
              const SizedBox(height: 8),
              Text(plugin.displayName, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              installed
                  ? IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Désinstaller',
                onPressed: onUninstall,
              )
                  : IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Installer',
                onPressed: onInstall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}