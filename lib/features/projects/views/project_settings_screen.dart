// lib/features/projects/views/project_settings_screen.dart

import 'package:flutter/material.dart';

import '../../../main.dart'; // pour AppColors
import 'package:tokan/core/services/plugin_registry.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/plugin_provider.dart';
import 'package:tokan/features/projects/services/project_service.dart';

/// Écran de paramètres d’un projet,
/// qui expose un toggle par plugin installé pour activer/désactiver son onglet.
class ProjectSettingsScreen extends StatefulWidget {
  final String projectId;
  const ProjectSettingsScreen({Key? key, required this.projectId})
      : super(key: key);

  @override
  State<ProjectSettingsScreen> createState() => _ProjectSettingsScreenState();
}

class _ProjectSettingsScreenState extends State<ProjectSettingsScreen> {
  final _projectService = ProjectService();
  bool _loading = true;
  final Map<String, bool> _activated = {};

  @override
  void initState() {
    super.initState();
    _loadActivatedPlugins();
  }

  Future<void> _loadActivatedPlugins() async {
    try {
      final active =
      await _projectService.getActivatedPlugins(widget.projectId);
      for (final plugin in PluginRegistry().availablePlugins) {
        _activated[plugin.id] = active.contains(plugin.id);
      }
    } catch (e) {
      debugPrint('Erreur chargement plugins : $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggle(String pluginId, bool value) async {
    setState(() => _activated[pluginId] = value);
    try {
      await _projectService.setPluginActivation(
          widget.projectId, pluginId, value);
    } catch (e) {
      debugPrint('Erreur mise à jour plugin : $e');
      setState(() => _activated[pluginId] = !value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pluginProv = context.watch<PluginProvider>();
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkGreyBackground,
        foregroundColor: Colors.white,
        title: const Text('Paramètres du projet'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: PluginRegistry()
            .availablePlugins
            .map((plugin) {
          final installed = pluginProv.isInstalled(plugin.id);
          if (!installed) {
            return ListTile(
              leading: Icon(plugin.iconData, color: Colors.white),
              title: Text('Plugin ${plugin.displayName} non installé',
                  style: const TextStyle(color: Colors.white)),
            );
          }
          return SwitchListTile(
            title: Text(plugin.displayName,
                style: const TextStyle(color: Colors.white)),
            secondary: Icon(plugin.iconData, color: Colors.white),
            activeColor: AppColors.green,
            value: _activated[plugin.id] ?? false,
            onChanged: (val) => _toggle(plugin.id, val),
          );
        }).toList(),
      ),
    );
  }
}