import 'package:flutter/material.dart';

/// Chaque plugin doit implémenter ce contrat.
abstract class PluginContract {
  /// ID unique du plugin (persistance, installation…)
  String get id;

  /// Nom à afficher dans le menu
  String get displayName;

  /// Icone Material pour le menu
  IconData get iconData;

  /// Écran principal du plugin
  Widget buildMainScreen(BuildContext context);

  /// (Optionnel) Widget de statistiques pour le dashboard
  Widget? buildDashboardWidget(BuildContext context);
}
