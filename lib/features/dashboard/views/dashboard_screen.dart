// lib/features/dashboard/views/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/plugin_provider.dart';
import '../../../core/services/plugin_registry.dart';
import '../widgets/project_progress_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showProjectWidget = true;
  final Map<String, bool> _pluginVisibility = {};

  @override
  Widget build(BuildContext context) {
    final pluginProv = context.watch<PluginProvider>();

    // 1. Construire la liste des widgets de statistiques
    final List<Widget> statWidgets = [];

    // Si l’utilisateur veut voir le widget de projet, on l’ajoute
    if (_showProjectWidget) {
      statWidgets.add(const ProjectProgressWidget());
    }

    // Pour chaque plugin installé, on récupère son widget de dashboard
    for (final plug in allPlugins) {
      if (pluginProv.isInstalled(plug.id)) {
        // Initialiser l’état du toggle s’il n’existe pas
        _pluginVisibility.putIfAbsent(plug.id, () => true);
        if (_pluginVisibility[plug.id] == true) {
          final w = plug.buildDashboardWidget(context);
          if (w != null) {
            statWidgets.add(w);
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          // Nouveau bouton pour ouvrir le panneau d’activation/désactivation
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Gérer les widgets',
            onPressed: () => _openWidgetSettings(context, pluginProv),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (statWidgets.isEmpty)
              const Center(child: Text('Aucun widget à afficher.'))
            else
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount;
                    if (constraints.maxWidth < 600) {
                      crossAxisCount = 1;
                    } else if (constraints.maxWidth < 900) {
                      crossAxisCount = 2;
                    } else {
                      crossAxisCount = 3;
                    }

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: statWidgets.length,
                      itemBuilder: (context, index) {
                        final w = statWidgets[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: w,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openWidgetSettings(
      BuildContext context, PluginProvider pluginProv) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          // Construire la liste des toggles : projet + plugins installés
          final items = <Widget>[];

          // Toggle pour le widget Projet
          items.add(
            SwitchListTile(
              title: const Text('Suivi de projet'),
              value: _showProjectWidget,
              onChanged: (val) {
                setState(() => _showProjectWidget = val);
                setModalState(() {});
              },
            ),
          );
          items.add(const Divider());

          // Toggles pour chaque plugin installé
          for (final plug in allPlugins) {
            if (pluginProv.isInstalled(plug.id) &&
                plug.buildDashboardWidget(context) != null) {
              // Assurer que la clé existe
              _pluginVisibility.putIfAbsent(plug.id, () => true);
              items.add(
                SwitchListTile(
                  title: Text(plug.displayName),
                  value: _pluginVisibility[plug.id]!,
                  onChanged: (val) {
                    setState(() => _pluginVisibility[plug.id] = val);
                    setModalState(() {});
                  },
                ),
              );
            }
          }

          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: items,
            ),
          );
        });
      },
    );
  }
}
