// lib/features/library/views/library_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tokan/core/providers/plugin_provider.dart';
import 'package:tokan/core/contract/plugin_contract.dart';
import '../../../main.dart'; // Pour AppColors

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = (width / 110).floor().clamp(1, 8);
              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 4 / 3,
                ),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final p = filtered[i];
                  final installed = pluginProv.isInstalled(p.id);
                  return Card(
                    color: AppColors.glassBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(p.iconData, size: 24),
                          Text(
                            p.displayName,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          ElevatedButton(
                            onPressed: () => installed
                                ? pluginProv.uninstall(p.id)
                                : pluginProv.install(p.id),
                            child:
                                Text(installed ? 'Désinstaller' : 'Installer'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
