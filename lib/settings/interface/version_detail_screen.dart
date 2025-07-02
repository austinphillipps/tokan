import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/update_manager.dart';

class VersionDetailScreen extends StatelessWidget {
  const VersionDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mgr = context.watch<UpdateManager>();

    return Scaffold(
      appBar: AppBar(title: const Text('Détails de la version')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version actuelle : ${mgr.currentVersion}'),
            const SizedBox(height: 8),
            Text('Dernière version : ${mgr.latestVersion}'),
            const SizedBox(height: 24),

            // Bouton Vérifier/Télécharger
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (mgr.status == UpdateStatus.checking ||
                    mgr.status == UpdateStatus.downloading)
                    ? null
                    : () => mgr.checkForUpdate(context),
                child: mgr.status == UpdateStatus.checking
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Vérifier les mises à jour'),
              ),
            ),

            const SizedBox(height: 16),

            // Progression
            if (mgr.status == UpdateStatus.downloading) ...[
              const Text('Téléchargement en cours :'),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: mgr.progress),
              const SizedBox(height: 16),
            ],

            // Erreur
            if (mgr.status == UpdateStatus.error && mgr.errorMessage != null) ...[
              Text('Erreur : ${mgr.errorMessage}',
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
            ],

            // Installation manuelle
            if (mgr.status == UpdateStatus.downloaded) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: mgr.installUpdate,
                  child: const Text('Installer la mise à jour'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
