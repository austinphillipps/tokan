import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/plugin_registry.dart';
import 'package:tokan/core/contract/plugin_contract.dart';

/// Gère la liste des plugins installés (persistés avec SharedPreferences).
class PluginProvider extends ChangeNotifier {
  static const _key = 'installedPlugins';
  static const _widgetKey = 'enabledDashboardWidgets';

  final PluginRegistry registry = PluginRegistry();
  final Set<String> _installed = {};
  final Set<String> _enabledWidgets = {};
  bool _initialized = false;

  bool get isInitialized => _initialized;
  List<String> get installedIds => List.unmodifiable(_installed);
  List<PluginContract> get installedPlugins => registry.availablePlugins
      .where((p) => _installed.contains(p.id))
      .toList();
  List<PluginContract> get enabledWidgetPlugins => registry.availablePlugins
      .where((p) => _installed.contains(p.id) && _enabledWidgets.contains(p.id))
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
    final widgetsSaved = prefs.getStringList(_widgetKey) ?? [];
    _enabledWidgets
      ..clear()
      ..addAll(widgetsSaved);
    _initialized = true;
    notifyListeners();
  }

  bool isInstalled(String id) => _installed.contains(id);
  bool isWidgetEnabled(String id) => _enabledWidgets.contains(id);

  Future<void> install(String id) async {
    if (_installed.add(id)) {
      _enabledWidgets.add(id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _installed.toList());
      await prefs.setStringList(_widgetKey, _enabledWidgets.toList());
      notifyListeners();
    }
  }

  Future<void> uninstall(String id) async {
    if (_installed.remove(id)) {
      _enabledWidgets.remove(id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _installed.toList());
      await prefs.setStringList(_widgetKey, _enabledWidgets.toList());
      notifyListeners();
    }
  }

  Future<void> toggle(String id) async {
    if (_installed.contains(id)) {
      _installed.remove(id);
      _enabledWidgets.remove(id);
    } else {
      _installed.add(id);
      _enabledWidgets.add(id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _installed.toList());
    await prefs.setStringList(_widgetKey, _enabledWidgets.toList());
    notifyListeners();
  }

  Future<void> toggleWidget(String id) async {
    if (_enabledWidgets.contains(id)) {
      _enabledWidgets.remove(id);
    } else {
      _enabledWidgets.add(id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_widgetKey, _enabledWidgets.toList());
    notifyListeners();
  }
}