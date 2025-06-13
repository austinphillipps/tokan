import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';

Future<void> checkForUpdate(BuildContext context) async {
  try {
    final PackageInfo info = await PackageInfo.fromPlatform();
    final response = await http.get(Uri.parse('https://example.com/version.json'));
    if (response.statusCode != 200) {
      _showError(context, 'Impossible de vérifier les mises à jour.');
      return;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final String remoteVersion = data['version'] as String? ?? '';
    final String url = data['url'] as String? ?? '';

    if (_isNewer(remoteVersion, info.version)) {
      try {
        await OtaUpdate().execute(url);
      } catch (_) {
        _showError(context, 'Échec du téléchargement ou permission refusée.');
      }
    }
  } catch (_) {
    _showError(context, 'Erreur lors de la vérification des mises à jour.');
  }
}

bool _isNewer(String remote, String local) {
  final r = remote.split('.').map(int.parse).toList();
  final l = local.split('.').map(int.parse).toList();
  for (var i = 0; i < r.length && i < l.length; i++) {
    if (r[i] > l[i]) return true;
    if (r[i] < l[i]) return false;
  }
  return r.length > l.length;
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
