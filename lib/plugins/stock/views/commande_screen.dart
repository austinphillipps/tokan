// lib/features/stock/screens/commande_screen.dart

import 'package:flutter/material.dart';

class CommandeScreen extends StatefulWidget {
  const CommandeScreen({Key? key}) : super(key: key);

  @override
  _CommandeScreenState createState() => _CommandeScreenState();
}

class _CommandeScreenState extends State<CommandeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  // Exemple de liste de commandes (à remplacer par votre source réelle)
  final List<Map<String, String>> _commandes = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color primaryColor = theme.colorScheme.primary;
    final Color onPrimary = theme.colorScheme.onPrimary;
    final Color backgroundColor = theme.scaffoldBackgroundColor;
    final Color onBackground = theme.colorScheme.onBackground;

    // Filtrage local à partir de _searchCtrl.text
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = _commandes.where((cmd) {
      final id = (cmd['id'] ?? '').toLowerCase();
      final prod = (cmd['produit'] ?? '').toLowerCase();
      final client = (cmd['client'] ?? '').toLowerCase();
      final vendeur = (cmd['vendeur'] ?? '').toLowerCase();
      return id.contains(query) ||
          prod.contains(query) ||
          client.contains(query) ||
          vendeur.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text('Commandes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nouvelle commande',
            onPressed: () {
              // TODO: Ouvrir le formulaire de création de commande
            },
            color: theme.iconTheme.color,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            color: primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(color: onPrimary),
                    cursorColor: onPrimary,
                    decoration: InputDecoration(
                      hintText: 'Rechercher commandes...',
                      hintStyle: TextStyle(color: onPrimary.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.search, color: onPrimary),
                      filled: true,
                      fillColor: theme.brightness == Brightness.dark
                          ? Colors.white10
                          : Colors.grey[100],
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.filter_list, color: onPrimary),
                  tooltip: 'Filtres avancés',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: theme.dialogBackgroundColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (_) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Filtres avancés commandes',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: onBackground)),
                            const SizedBox(height: 12),
                            Text('Fonctionnalité en cours de développement…',
                                style: TextStyle(color: onBackground)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // DataTable des commandes
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: theme.cardColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor:
                    MaterialStateProperty.all(primaryColor.withOpacity(0.1)),
                    dataRowColor: MaterialStateProperty.resolveWith((states) =>
                    theme.brightness == Brightness.dark
                        ? Colors.white10
                        : Colors.grey[50]),
                    headingTextStyle: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    columns: const [
                      DataColumn(label: Text('ID Commande')),
                      DataColumn(label: Text('Produit')),
                      DataColumn(label: Text('Quantité')),
                      DataColumn(label: Text('Client')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Vendeur')),
                      DataColumn(label: Text('Statut')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: filtered.map((cmd) {
                      return DataRow(
                        cells: [
                          DataCell(Text(cmd['id'] ?? '',
                              style: TextStyle(color: onBackground))),
                          DataCell(Text(cmd['produit'] ?? '',
                              style: TextStyle(color: onBackground))),
                          DataCell(Text(cmd['quantite'] ?? '',
                              style: TextStyle(color: onBackground))),
                          DataCell(Text(cmd['client'] ?? '',
                              style: TextStyle(color: onBackground))),
                          DataCell(Text(cmd['date'] ?? '',
                              style: TextStyle(color: onBackground))),
                          DataCell(Text(cmd['vendeur'] ?? '',
                              style: TextStyle(color: onBackground))),
                          DataCell(Text(cmd['statut'] ?? '',
                              style: TextStyle(color: onBackground))),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility, size: 20),
                                tooltip: 'Voir détails',
                                color: primaryColor,
                                onPressed: () {
                                  // TODO: Afficher détails de la commande
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                tooltip: 'Modifier',
                                color: primaryColor,
                                onPressed: () {
                                  // TODO: Modifier la commande
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                tooltip: 'Supprimer',
                                color: Colors.redAccent,
                                onPressed: () {
                                  // TODO: Supprimer la commande
                                },
                              ),
                            ],
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
