import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PluginProvider extends ChangeNotifier {
  static const _key = 'installedPlugins';
  final Set<String> _installed = {};

  PluginProvider() { _load(); }

  List<String> get installedIds => _installed.toList();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _installed.addAll(prefs.getStringList(_key) ?? []);
    notifyListeners();
  }

  Future<void> toggle(String id) async {
    final prefs = await SharedPreferences.getInstance();
    if (_installed.contains(id)) _installed.remove(id);
    else _installed.add(id);
    await prefs.setStringList(_key, _installed.toList());
    notifyListeners();
  }

  bool isInstalled(String id) => _installed.contains(id);
}
