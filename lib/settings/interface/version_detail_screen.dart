import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tokan/services/update_manager.dart';
import '../../main.dart'; // Pour AppTheme & themeNotifier

class VersionDetailScreen extends StatefulWidget {
  const VersionDetailScreen({Key? key}) : super(key: key);

  @override
  _VersionDetailScreenState createState() => _VersionDetailScreenState();
}

class _VersionDetailScreenState extends State<VersionDetailScreen> {
  late final UpdateManager _updateManager;

  @override
  void initState() {
    super.initState();
    // Initialise le gestionnaire et lance la vérification
    _updateManager = UpdateManager();
    _updateManager.checkForUpdate();
  }

  @override
  void dispose() {
    _updateManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkStyle = themeNotifier.value == AppTheme.dark;

    return ChangeNotifierProvider<UpdateManager>.value(
      value: _updateManager,
      child: Consumer<UpdateManager>(
        builder: (context, manager, _) {
          final status = manager.status;
          final current = manager.currentVersion ?? '...';
          final latest = manager.latestVersion ?? '...';

          return Scaffold(
            backgroundColor: isDarkStyle
                ? Colors.grey[900]
                : Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(title: const Text('Détails de la mise à jour')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Version actuelle : $current'),
                  Text('Dernière version : $latest'),
                  const SizedBox(height: 24),

                  // État de vérification
                  if (status == UpdateStatus.checking) ...[
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 8),
                    const Text('Vérification de la mise à jour...'),
                  ],

                  // À jour
                  if (status == UpdateStatus.upToDate) ...[
                    const Icon(Icons.check_circle, size: 48, color: Colors.green),
                    const SizedBox(height: 8),
                    const Text('Votre application est à jour.'),
                  ],

                  // Erreur
                  if (status == UpdateStatus.error) ...[
                    const Icon(Icons.error, size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Erreur : ${manager.errorMessage ?? 'Impossible de vérifier.'}'),
                  ],

                  // Mise à jour dispo
                  if (status == UpdateStatus.available) ...[
                    const Text('Une mise à jour est disponible !'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: manager.downloadUpdate,
                      child: const Text('Télécharger la mise à jour'),
                    ),
                  ],

                  // En cours de téléchargement
                  if (status == UpdateStatus.downloading) ...[
                    Text('Téléchargement : ${(manager.progress * 100).toStringAsFixed(0)} %'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: manager.progress),
                  ],

                  // Téléchargé
                  if (status == UpdateStatus.downloaded) ...[
                    const Text('Téléchargement terminé.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: manager.installUpdate,
                      child: const Text('Installer la mise à jour'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
