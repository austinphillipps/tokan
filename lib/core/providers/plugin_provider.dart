import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/plugin_registry.dart';
import 'package:tokan/core/contract/plugin_contract.dart';

/// Gère la liste des plugins installés (persistés avec SharedPreferences).
class PluginProvider extends ChangeNotifier {
  static const _key = 'installedPlugins';

  final PluginRegistry registry = PluginRegistry();
  final Set<String> _installed = {};
  bool _initialized = false;

  bool get isInitialized => _initialized;
  List<String> get installedIds => List.unmodifiable(_installed);
  List<PluginContract> get installedPlugins => registry.availablePlugins
      .where((p) => _installed.contains(p.id))
      .toList();

  PluginProvider() {
    _loadInstalledPlugins();
  }

  Future<void> _loadInstalledPlugins() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key) ?? [];
    _installed
      ..clear()
      ..addAll(saved);
    _initialized = true;
    notifyListeners();
  }

  bool isInstalled(String id) => _installed.contains(id);

  Future<void> install(String id) async {
    if (_installed.add(id)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _installed.toList());
      notifyListeners();
    }
  }

  Future<void> uninstall(String id) async {
    if (_installed.remove(id)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _installed.toList());
      notifyListeners();
    }
  }

  Future<void> toggle(String id) async {
    if (_installed.contains(id)) {
      _installed.remove(id);
    } else {
      _installed.add(id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _installed.toList());
    notifyListeners();
  }
}
