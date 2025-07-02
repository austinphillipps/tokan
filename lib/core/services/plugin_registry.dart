// lib/plugins/plugin_registry.dart

import 'package:tokan/core/contract/plugin_contract.dart';
import '../../plugins/crm/services/crm_plugin.dart';
// import '../../plugins/fsm/services/fsm_plugin.dart';
// import '../../plugins/esp/services/esp_plugin.dart';

/// Registre de tous les plugins disponibles.
/// Quand vous créez un nouveau plugin, copiez-collez la ligne correspondante ci-dessous.
class PluginRegistry {
  /// Liste de tous les plugins installés dans l’application.
  List<PluginContract> get availablePlugins => [
    CrmPlugin(),
    // FsmPlugin(),
    // EspPlugin(),
  ];
}