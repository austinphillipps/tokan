// lib/features/library/views/library_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tokan/core/providers/plugin_provider.dart';
import 'package:tokan/core/contract/plugin_contract.dart';
import '../widgets/plugin_card.dart';

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
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 4 / 5,
            ),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final p = filtered[i];
              final installed = pluginProv.isInstalled(p.id);
              return PluginCard(
                plugin: p,
                installed: installed,
                onInstall: () => pluginProv.install(p.id),
                onUninstall: () => pluginProv.uninstall(p.id),
              );
            },
          ),
        ),
      ],
    );
  }
}
