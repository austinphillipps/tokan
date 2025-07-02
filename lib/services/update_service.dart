import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show consolidateHttpClientResponseBytes;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Service de mise à jour multiplate‑forme (Windows + macOS).
///
/// Le fichier JSON hébergé doit avoir la structure suivante :
/// ```json
/// {
///   "latest_version": "1.0.5",
///   "windows": {
///     "url": "https://example.com/FrameCastle_v1.0.5.exe"
///   },
///   "macos": {
///     "url": "https://example.com/FrameCastle_v1.0.5.dmg"
///   }
/// }
/// ```
class UpdateService {
  /// URL du fichier JSON décrivant la dernière version.
  static const String _versionUrl =
      'https://framecastle-studio.com/updates/version.json';

  // Garde en mémoire qu'on a déjà vérifié cette session
  static bool _hasChecked = false;

  /// Point d’entrée appelé depuis l’UI pour vérifier puis proposer une mise à jour.
  static Future<void> checkForUpdate(BuildContext context) async {
    if (_hasChecked) return;
    _hasChecked = true;

    debugPrint('🔍 Checking update at $_versionUrl');

    try {
      final response = await http.get(Uri.parse(_versionUrl));
      debugPrint('📶 HTTP ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('⛔️ Version file not reachable');
        return;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final latestVersion = data['latest_version'] as String?;
      if (latestVersion == null) {
        debugPrint('⚠️ latest_version missing in JSON');
        return;
      }

      // --- Sélectionne l’URL d’update selon la plateforme ----------------------------------
      String? updateUrl;
      if (Platform.isWindows) {
        updateUrl = (data['windows'] as Map<String, dynamic>?)?['url'] as String?;
      } else if (Platform.isMacOS) {
        updateUrl = (data['macos'] as Map<String, dynamic>?)?['url'] as String?;
      }

      if (updateUrl == null) {
        debugPrint('🚫 No update URL for this platform');
        return;
      }

      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;
      debugPrint('ℹ️ currentVersion=$currentVersion – latestVersion=$latestVersion');

      if (!_isNewer(currentVersion, latestVersion)) {
        debugPrint('✅ Up to date');
        return;
      }
      debugPrint('⚡ New version detected');

      // --- Demande confirmation à l’utilisateur ---------------------------------------------
      // ignore: use_build_context_synchronously
      final confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Mise à jour disponible'),
          content: Text(
              'Une nouvelle version ($latestVersion) est disponible. Voulez‑vous installer maintenant ?'),
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

      if (confirm == true) await _downloadAndInstall(updateUrl);
    } catch (e, st) {
      debugPrint('❌ Erreur mise à jour : $e\n$st');
    }
  }

  // -------------------------------------------------------------------------------------------------
  // Téléchargement + exécution de l’installateur puis fermeture de l’app
  // -------------------------------------------------------------------------------------------------
  static Future<void> _downloadAndInstall(String url) async {
    debugPrint('⬇️ Downloading update from $url');

    // 1) Télécharge le fichier dans le dossier temporaire
    final tmpDir = await getTemporaryDirectory();
    final fileName = _suggestedFileName(url);
    final filePath = '${tmpDir.path}/$fileName';

    final request = await HttpClient().getUrl(Uri.parse(url));
    final response = await request.close();
    final bytes = await consolidateHttpClientResponseBytes(response);

    final file = File(filePath);
    await file.writeAsBytes(bytes);
    debugPrint('💾 Update downloaded to $filePath');

    // 2) Exécute l’installateur selon la plateforme
    if (Platform.isWindows) {
      await Process.start(filePath, [], mode: ProcessStartMode.detached);
    } else if (Platform.isMacOS) {
      if (filePath.endsWith('.pkg')) {
        await Process.start('installer', ['-pkg', filePath, '-target', '/'],
            mode: ProcessStartMode.detached);
      } else {
        await Process.start('open', [filePath],
            mode: ProcessStartMode.detached);
      }
    }

    // 3) Ferme l’application courante pour laisser l’installateur faire son travail
    exit(0);
  }

  // -------------------------------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------------------------------
  /// Suggestion d’extension locale à partir de l’URL.
  static String _suggestedFileName(String url) {
    final uri = Uri.parse(url);
    final extension = uri.pathSegments.last.split('.').last;
    return 'update_installer.$extension';
  }

  /// Compare deux versions « major.minor.patch ».
  static bool _isNewer(String current, String latest) {
    List<int> toInts(String v) =>
        v.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final c = toInts(current);
    final l = toInts(latest);
    for (var i = 0; i < l.length; i++) {
      final cv = c.length > i ? c[i] : 0;
      final lv = l[i];
      if (cv < lv) return true;
      if (cv > lv) return false;
    }
    return false;
  }
}
