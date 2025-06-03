// lib/features/projects/views/project_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/plugin_provider.dart';
import '../models/project_models.dart';

class ProjectSettingsScreen extends StatefulWidget {
  final Project project;

  const ProjectSettingsScreen({
    Key? key,
    required this.project,
  }) : super(key: key);

  @override
  _ProjectSettingsScreenState createState() => _ProjectSettingsScreenState();
}

class _ProjectSettingsScreenState extends State<ProjectSettingsScreen> {
  bool _stockEnabled = false;
  bool _commandeEnabled = false;

  late List<String> _currentPlugins;
  late PluginProvider _pluginProvider;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentPlugins = [];
    // On chargera la liste à jour depuis Firestore
    _loadPluginsFromFirestore();
  }

  Future<void> _loadPluginsFromFirestore() async {
    final docRef =
    FirebaseFirestore.instance.collection('projects').doc(widget.project.id);
    final snapshot = await docRef.get();
    final data = snapshot.data();
    final existing = (data != null && data['plugins'] is List<dynamic>)
        ? List<String>.from(data!['plugins'])
        : <String>[];

    setState(() {
      _currentPlugins = existing;
      _stockEnabled = existing.contains('stock');
      _commandeEnabled = existing.contains('commande');
      _loading = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pluginProvider = Provider.of<PluginProvider>(context);
  }

  Future<void> _toggleStock(bool enable) async {
    final projectId = widget.project.id;
    final docRef =
    FirebaseFirestore.instance.collection('projects').doc(projectId);

    setState(() => _stockEnabled = enable);

    if (enable) {
      if (!_currentPlugins.contains('stock')) {
        _currentPlugins.add('stock');
        await docRef.update({
          'plugins': FieldValue.arrayUnion(['stock']),
        });
      }
    } else {
      if (_currentPlugins.contains('stock')) {
        _currentPlugins.remove('stock');
        await docRef.update({
          'plugins': FieldValue.arrayRemove(['stock']),
        });
      }
    }
  }

  Future<void> _toggleCommande(bool enable) async {
    final projectId = widget.project.id;
    final docRef =
    FirebaseFirestore.instance.collection('projects').doc(projectId);

    setState(() => _commandeEnabled = enable);

    if (enable) {
      if (!_currentPlugins.contains('commande')) {
        _currentPlugins.add('commande');
        await docRef.update({
          'plugins': FieldValue.arrayUnion(['commande']),
        });
      }
    } else {
      if (_currentPlugins.contains('commande')) {
        _currentPlugins.remove('commande');
        await docRef.update({
          'plugins': FieldValue.arrayRemove(['commande']),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    // On n’affiche les switches que si le plugin global “stock” est installé
    final isStockInstalled = _pluginProvider.isInstalled('stock');

    if (_loading) {
      // On attend que la requête Firestore revienne
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Paramètres du projet', style: TextStyle(color: onSurface)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fonctionnalités',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (isStockInstalled) ...[
              // ─── Switch “Stock” ───────────────────────────────
              SwitchListTile(
                title: const Text('Stock'),
                subtitle: const Text('Activer l’onglet Stock pour ce projet'),
                secondary: const Icon(Icons.store_rounded),
                value: _stockEnabled,
                onChanged: (val) => _toggleStock(val),
              ),
              const SizedBox(height: 16),

              // ─── Switch “Commandes” ────────────────────────────
              SwitchListTile(
                title: const Text('Commandes'),
                subtitle:
                const Text('Activer l’onglet Commandes pour ce projet'),
                secondary: const Icon(Icons.receipt_long),
                value: _commandeEnabled,
                onChanged: (val) => _toggleCommande(val),
              ),
            ] else ...[
              // Si “stock” n’est pas installé, on affiche un message grisé
              ListTile(
                leading: const Icon(Icons.block, color: Colors.grey),
                title: const Text(
                  'Stock & Commandes',
                  style: TextStyle(color: Colors.grey),
                ),
                subtitle: const Text(
                  'Le plugin Stock n’est pas installé.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
