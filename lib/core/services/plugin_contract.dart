import 'package:flutter/material.dart';

/// Interface que doit implémenter chaque plugin de l’app
abstract class PluginContract {
  /// Identifiant unique, utilisé pour l’installation/persistance
  String get id;

  /// Nom affichable dans l’UI (Library, menu, titre…)
  String get displayName;

  /// Icône du plugin (pour la Library, le menu…)
  Widget get icon;

  /// L’écran principal renvoyé par le plugin
  Widget buildMainScreen(BuildContext context);

  /// (Optionnel) Widget de stats à injecter dans le Dashboard
  Widget? buildDashboardWidget(BuildContext context);
}
