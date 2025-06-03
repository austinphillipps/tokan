// lib/core/plugin_contract.dart

import 'package:flutter/widgets.dart';

/// Contrat que doit implémenter chaque plugin pour
/// pouvoir être reconnu et chargé dynamiquement.
abstract class PluginContract {
  /// Identifiant unique du plugin (doit être constant).
  String get id;

  /// Nom affiché dans la Library et dans la sidebar.
  String get displayName;

  /// Icône représentant le plugin dans la sidebar (ou la Library).
  /// Tu peux renvoyer un `Icon`, un `ImageIcon`, etc.
  Widget get icon;

  /// Écran principal du plugin. Lorsqu’on clique sur l’icône
  /// du plugin dans la barre de menu, on appelle cette méthode.
  Widget buildMainScreen(BuildContext context);

  /// Si le plugin fournit un widget de statistiques à afficher
  /// dans le dashboard (dans la section "Statistiques"), renvoyer
  /// un widget ici. Sinon, renvoyer `null`.
  Widget? buildDashboardWidget(BuildContext context);
}
