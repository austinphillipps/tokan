import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gère la liste des widgets de dashboard activés.
class DashboardWidgetProvider extends ChangeNotifier {
  static const _prefsKey = 'enabledDashboardWidgets';

  final Set<String> _enabled = {};
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// S'assure que les [ids] spécifiés existent dans la liste activée.
  /// Si aucune préférence n'a encore été sauvegardée, on active tout par défaut.
  Future<void> ensureDefaults(Iterable<String> ids) async {
    if (!_initialized) return;
    if (_enabled.isEmpty) {
      _enabled.addAll(ids);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _enabled.toList());
      notifyListeners();
    }
  }

  DashboardWidgetProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey) ?? [];
    _enabled
      ..clear()
      ..addAll(saved);
    _initialized = true;
    notifyListeners();
  }

  bool isEnabled(String id) => _enabled.contains(id);

  Future<void> toggle(String id) async {
    if (_enabled.contains(id)) {
      _enabled.remove(id);
    } else {
      _enabled.add(id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _enabled.toList());
    notifyListeners();
  }
}