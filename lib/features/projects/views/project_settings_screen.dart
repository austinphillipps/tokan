// lib/features/projects/views/project_settings_screen.dart

import 'package:flutter/material.dart';

import '../../../main.dart'; // pour AppColors
import 'package:tokan/core/services/plugin_registry.dart';
import 'package:tokan/core/providers/plugin_provider.dart';
import 'package:provider/provider.dart';
import 'package:tokan/features/projects/services/project_service.dart';
import '../../../plugins/crm/services/crm_plugin.dart';

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
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkGreyBackground,
        foregroundColor: Colors.white,
        title: const Text('Paramètres du projet'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Builder(
        builder: (context) {
          final pluginProv = context.watch<PluginProvider>();
          final bool crmInstalled = pluginProv.isInstalled('crm');

          final pluginToggles = PluginRegistry()
              .availablePlugins
              .map((plugin) => SwitchListTile(
            title: Text(plugin.displayName,
                style: const TextStyle(color: Colors.white)),
            secondary: Icon(plugin.iconData, color: Colors.white),
            activeColor: AppColors.green,
            value: _activated[plugin.id] ?? false,
            onChanged: (val) => _toggle(plugin.id, val),
          ))
              .toList();

          pluginToggles.add(const Divider(color: Colors.white24));

          pluginToggles.add(
            ListTile(
              enabled: crmInstalled,
              leading: Icon(Icons.business_center,
                  color: crmInstalled ? Colors.white : Colors.grey),
              title: const Text('CRM',
                  style: TextStyle(color: Colors.white)),
              subtitle: crmInstalled
                  ? null
                  : const Text(
              'Le plugin CRM n\'est pas installé',
              style: TextStyle(color: Colors.grey),
            ),
              onTap: crmInstalled
                  ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CrmPlugin().buildMainScreen(context),
                  ),
                );
              }
                  : null,
            ),
          );

          return ListView(children: pluginToggles);
        },
      ),
    );
  }
}
