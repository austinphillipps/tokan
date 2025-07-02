// lib/services/update_manager.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../main.dart'; // pour navigatorKey

enum UpdateStatus {
  idle,
  checking,
  available,
  downloading,
  downloaded,
  upToDate,
  error,
}

class UpdateManager extends ChangeNotifier {
  UpdateStatus status = UpdateStatus.idle;
  double progress = 0.0;
  String currentVersion = '0.0.0';
  String latestVersion = '0.0.0';
  String? downloadUrl;
  File? downloadedFile;
  String? errorMessage;

  UpdateManager() {
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    currentVersion = info.version;
    notifyListeners();
  }

  /// Vérifie la version en ligne et, si besoin, déclenche le téléchargement.
  Future<void> checkForUpdate(BuildContext context) async {
    status = UpdateStatus.checking;
    errorMessage = null;
    notifyListeners();

    try {
      final resp = await http.get(
        Uri.parse('https://framecastle-studio.com/updates/version.json'),
      );
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      latestVersion = data['latest_version'] as String;

      downloadUrl = Platform.isWindows
          ? (data['windows']?['url'] as String?)
          : Platform.isMacOS
          ? (data['macos']?['url'] as String?)
          : null;

      if (downloadUrl == null) {
        status = UpdateStatus.error;
        errorMessage = 'Pas de mise à jour pour cette plateforme.';
        notifyListeners();
      }
      else if (_isNewer(currentVersion, latestVersion)) {
        status = UpdateStatus.available;
        notifyListeners();

        final consent = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Mise à jour disponible'),
            content: Text(
                'Version $latestVersion disponible (vous avez $currentVersion). '
                    'Télécharger et installer ?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Plus tard'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Mettre à jour'),
              ),
            ],
          ),
        );

        if (consent == true) {
          await downloadUpdate();
        } else {
          status = UpdateStatus.idle;
          notifyListeners();
        }
      }
      else {
        status = UpdateStatus.upToDate;
        notifyListeners();
      }
    } catch (e) {
      status = UpdateStatus.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Télécharge l’installateur et notifie la progression.
  Future<void> downloadUpdate() async {
    if (downloadUrl == null) return;

    status = UpdateStatus.downloading;
    progress = 0.0;
    notifyListeners();

    final tmpDir = await getTemporaryDirectory();
    final ext = Platform.isWindows ? 'exe' : 'dmg';
    final file = File('${tmpDir.path}/update_installer.$ext');
    if (file.existsSync()) file.deleteSync();

    final req = await HttpClient().getUrl(Uri.parse(downloadUrl!));
    final response = await req.close();
    final total = response.contentLength;
    int received = 0;
    final sink = file.openWrite();

    await for (var chunk in response) {
      received += chunk.length;
      sink.add(chunk);
      progress = (total > 0) ? received / total : 0.0;
      notifyListeners();
    }
    await sink.close();

    downloadedFile = file;
    status = UpdateStatus.downloaded;
    notifyListeners();

    // Dès que c'est téléchargé, on propose l'installation
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      Future.microtask(() async {
        final installNow = await showDialog<bool>(
          context: ctx,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Installation prête'),
            content: const Text(
                'Le téléchargement est terminé.\n'
                    'Installer maintenant ?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Plus tard'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Installer'),
              ),
            ],
          ),
        );
        if (installNow == true) {
          await installUpdate();
        }
      });
    }
  }

  /// Lance l’installateur (via shell) puis ferme l’app immédiatement.
  Future<void> installUpdate() async {
    if (downloadedFile == null) return;

    try {
      if (Platform.isWindows) {
        await Process.start(
          'cmd',
          ['/C', 'start', '', downloadedFile!.path],
          mode: ProcessStartMode.detached,
          runInShell: true,
        );
      } else if (Platform.isMacOS) {
        await Process.start(
          'open',
          [downloadedFile!.path],
          mode: ProcessStartMode.detached,
          runInShell: true,
        );
      }
    } catch (_) {
      // en cas d'erreur, l'utilisateur peut lancer manuellement
    }

    // On ferme l'app après un tout petit délai pour laisser le shell démarrer le process
    Future.delayed(const Duration(milliseconds: 200), () => exit(0));
  }

  /// Compare deux versions “major.minor.patch”.
  bool _isNewer(String current, String latest) {
    List<int> toInts(String v) =>
        v.split(RegExp(r'[.+]')).map((e) => int.tryParse(e) ?? 0).toList();
    final c = toInts(current), l = toInts(latest);
    for (var i = 0; i < l.length; i++) {
      final ci = (c.length > i ? c[i] : 0);
      if (ci < l[i]) return true;
      if (ci > l[i]) return false;
    }
    return false;
  }
}
