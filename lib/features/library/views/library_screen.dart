// lib/pages/library_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/plugin_provider.dart';
import '../../../core/services/plugin_registry.dart';

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

    // Filtrer les plugins selon la recherche (par displayName)
    final filteredPlugins = allPlugins.where((plug) {
      return plug.displayName.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher un plugin...',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  _search = val;
                });
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                itemCount: filteredPlugins.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final plug = filteredPlugins[index];
                  final installed = pluginProv.isInstalled(plug.id);

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icône du plugin
                        plug.icon,
                        const SizedBox(height: 12),
                        // Nom du plugin
                        Text(
                          plug.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Bouton Installer / Désinstaller
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: installed ? Colors.red : Colors.green,
                          ),
                          onPressed: () => pluginProv.toggle(plug.id),
                          child: Text(
                            installed ? 'Désinstaller' : 'Installer',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
