import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

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
  double progress = 0.0;              // 0.0 à 1.0
  String currentVersion = '0.0.0';
  String latestVersion  = '0.0.0';
  String? downloadUrl;
  File?   downloadedFile;
  String? errorMessage;

  UpdateManager() {
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    currentVersion = info.version;
    notifyListeners();
  }

  Future<void> checkForUpdate() async {
    status = UpdateStatus.checking;
    notifyListeners();

    try {
      final resp = await http.get(Uri.parse('https://framecastle-studio.com/updates/version.json'));
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
      final data = Map<String, dynamic>.from(await http.read(Uri.parse(
          'https://framecastle-studio.com/updates/version.json')) as dynamic);
      latestVersion = data['latest_version'];
      // Choix de l’URL suivant la plateforme
      downloadUrl = Platform.isWindows
          ? (data['windows']?['url'] as String?)
          : Platform.isMacOS
          ? (data['macos']?['url'] as String?)
          : null;

      if (downloadUrl == null) {
        status = UpdateStatus.error;
        errorMessage = 'Pas de mise à jour pour cette plateforme.';
      } else if (_isNewer(currentVersion, latestVersion)) {
        status = UpdateStatus.available;
      } else {
        status = UpdateStatus.upToDate;
      }
    } catch (e) {
      status = UpdateStatus.error;
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  bool _isNewer(String current, String latest) {
    List<int> toInts(String v) =>
        v.split(RegExp(r'[.+]')).map((e) => int.tryParse(e) ?? 0).toList();
    final c = toInts(current), l = toInts(latest);
    for (var i = 0; i < l.length; i++) {
      if ((c.length > i ? c[i] : 0) < l[i]) return true;
      if ((c.length > i ? c[i] : 0) > l[i]) return false;
    }
    return false;
  }

  Future<void> downloadUpdate() async {
    if (downloadUrl == null) return;
    status = UpdateStatus.downloading;
    progress = 0.0;
    notifyListeners();

    final tmpDir = await getTemporaryDirectory();
    final fileName = Platform.isWindows ? 'update.exe' : 'update.dmg';
    final filePath = '${tmpDir.path}/$fileName';
    final file = File(filePath);
    if (file.existsSync()) file.deleteSync();

    final request = await HttpClient().getUrl(Uri.parse(downloadUrl!));
    final response = await request.close();
    final total = response.contentLength;
    int received = 0;
    final sink = file.openWrite();
    await for (var chunk in response) {
      received += chunk.length;
      sink.add(chunk);
      progress = total > 0 ? received / total : 0.0;
      notifyListeners();
    }
    await sink.close();
    downloadedFile = file;
    status = UpdateStatus.downloaded;
    notifyListeners();
  }

  Future<void> installUpdate() async {
    if (downloadedFile == null) return;
    status = UpdateStatus.idle; // ou installing
    notifyListeners();
    await Process.start(downloadedFile!.path, [], mode: ProcessStartMode.detached);
    exit(0);
  }
}
