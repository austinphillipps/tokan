// lib/shared/interface/interface.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/plugin_provider.dart';
import '../../core/services/plugin_registry.dart';

import '../../features/dashboard/views/dashboard_screen.dart';
import '../../features/tasks/views/tasks_screen.dart';
import '../../features/calendar/views/calendar_screen.dart';
import '../../features/projects/views/projects_screen.dart';
import '../../settings/views/settings_screen.dart';
import '../../features/chat/views/messages_screen.dart';
import '../../features/collaborators/views/collaborators_screen.dart';
import '../../features/notifications/views/notifications_screen.dart';
import '../../features/library/views/library_screen.dart';

// IMPORTER ici vos deux écrans Stock et Commandes
import '../../plugins/stock/views/stock_screen.dart';
import '../../plugins/stock/views/commande_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _sidebarExpanded = false;
  bool _showLabels = false;
  Timer? _labelTimer;

  final ValueNotifier<int> _calendarRefreshNotifier = ValueNotifier<int>(0);

  @override
  void dispose() {
    _labelTimer?.cancel();
    super.dispose();
  }

  void _onMouseEnter(_) {
    _labelTimer?.cancel();
    setState(() => _sidebarExpanded = true);
    _labelTimer = Timer(const Duration(milliseconds: 200), () {
      if (_sidebarExpanded) setState(() => _showLabels = true);
    });
  }

  void _onMouseExit(_) {
    _labelTimer?.cancel();
    setState(() {
      _showLabels = false;
      _sidebarExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Couleurs extraites du thème
    final sidebarBg = theme.colorScheme.surface;
    final mainBg = theme.colorScheme.background;
    final dividerColor = theme.colorScheme.onBackground.withOpacity(0.3);

    // Icônes
    final iconColorDefault = theme.colorScheme.onSurface;
    final iconColorSelected = theme.colorScheme.primary;

    // Fond pour item sélectionné
    final selectedItemBg = isDark
        ? theme.colorScheme.surfaceVariant ?? Colors.grey[800]!
        : theme.colorScheme.surfaceVariant ?? Colors.grey[200]!;

    // Récupérer PluginProvider
    final pluginProv = context.watch<PluginProvider>();

    // 1) Pages "de base" (indices 0..8)
    final List<Widget> defaultPages = [
      const DashboardScreen(),                       // 0
      const TasksPage(),                             // 1
      CalendarPage(refreshNotifier: _calendarRefreshNotifier), // 2
      const CollaboratorsPage(),                     // 3
      const MessagesPage(),                          // 4
      const NotificationsPage(),                     // 5
      const LibraryPage(),                           // 6
      ProjectsScreen(),                              // 7
      const SettingsPage(),                          // 8
    ];

    // 2) Icônes de base (indices 0..8)
    final List<IconData> defaultIcons = [
      Icons.home,           // 0
      Icons.task_alt,       // 1
      Icons.calendar_today, // 2
      Icons.group,          // 3
      Icons.message,        // 4
      Icons.notifications,  // 5
      Icons.library_books,  // 6
      Icons.work,           // 7
      Icons.settings,       // 8
    ];

    // 3) Labels de base (indices 0..8)
    final List<String> defaultLabels = [
      'Accueil',        // 0
      'Tâches',         // 1
      'Calendrier',     // 2
      'Collaborateurs', // 3
      'Messages',       // 4
      'Notifications',  // 5
      'Library',        // 6
      'Projets',        // 7
      'Paramètres',     // 8
    ];

    // 4) Construire listes finales en injectant Stock + Commandes après Projets
    final List<Widget> pages = [
      ...defaultPages.sublist(0, 8),
      // Si plugin "stock" est installé, ajouter d'abord StockScreen, puis CommandeScreen
      if (pluginProv.isInstalled('stock')) const StockScreen(),
      if (pluginProv.isInstalled('stock')) const CommandeScreen(),
      // Enfin, page "Paramètres"
      defaultPages.last,
    ];

    final List<IconData> icons = [
      ...defaultIcons.sublist(0, 8),
      if (pluginProv.isInstalled('stock')) Icons.inventory_2,  // icône Stock
      if (pluginProv.isInstalled('stock')) Icons.receipt_long, // icône Commandes
      defaultIcons.last,
    ];

    final List<String> labels = [
      ...defaultLabels.sublist(0, 8),
      if (pluginProv.isInstalled('stock')) 'Stock',
      if (pluginProv.isInstalled('stock')) 'Commandes',
      defaultLabels.last,
    ];

    return Scaffold(
      body: Row(
        children: [
          // ───────── Sidebar ─────────
          MouseRegion(
            onEnter: _onMouseEnter,
            onExit: _onMouseExit,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _sidebarExpanded ? 180 : 60,
              color: sidebarBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Items principaux (indices 0.. avant "Notifications", "Library", "Paramètres")
                  for (int i = 0; i < pages.length; i++)
                    if (labels[i] != 'Notifications' &&
                        labels[i] != 'Library' &&
                        labels[i] != 'Paramètres')
                      _buildNavItem(
                        index: i,
                        icon: icons[i],
                        label: labels[i],
                        iconColorDefault: iconColorDefault,
                        iconColorSelected: iconColorSelected,
                        selectedItemBg: selectedItemBg,
                      ),

                  const Spacer(),

                  // Notifications (toujours présent)
                  _buildNavIcon(
                    index: labels.indexOf('Notifications'),
                    icon: Icons.notifications,
                    iconColorDefault: iconColorDefault,
                    iconColorSelected: iconColorSelected,
                    selectedItemBg: selectedItemBg,
                  ),
                  const SizedBox(height: 8),

                  // Library
                  _buildNavIcon(
                    index: labels.indexOf('Library'),
                    icon: Icons.library_books,
                    iconColorDefault: iconColorDefault,
                    iconColorSelected: iconColorSelected,
                    selectedItemBg: selectedItemBg,
                  ),
                  const SizedBox(height: 8),

                  // Paramètres
                  _buildNavIcon(
                    index: labels.indexOf('Paramètres'),
                    icon: Icons.settings,
                    iconColorDefault: iconColorDefault,
                    iconColorSelected: iconColorSelected,
                    selectedItemBg: selectedItemBg,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ───────── Séparateur ─────────
          VerticalDivider(width: 1, color: dividerColor),

          // ───────── Contenu principal ─────────
          Expanded(
            child: Container(
              color: mainBg,
              child: pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit un item de navigation (icône + label si sidebar étendue)
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required Color iconColorDefault,
    required Color iconColorSelected,
    required Color selectedItemBg,
  }) {
    final bool selected = index == _selectedIndex;
    return Material(
      color: selected ? selectedItemBg : Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? iconColorSelected : iconColorDefault,
              ),
              if (_showLabels) ...[
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? iconColorSelected : iconColorDefault,
                  ),
                ),
              ] else
                Tooltip(message: label, child: const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit uniquement une icône pour Notifications, Library, Paramètres
  Widget _buildNavIcon({
    required int index,
    required IconData icon,
    required Color iconColorDefault,
    required Color iconColorSelected,
    required Color selectedItemBg,
  }) {
    final bool selected = index == _selectedIndex;
    return Material(
      color: selected ? selectedItemBg : Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Tooltip(
            message: labelForIndex(index),
            child: Icon(
              icon,
              color: selected ? iconColorSelected : iconColorDefault,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  /// Retourne le label associé à un index (pour Tooltip)
  String labelForIndex(int index) {
    final pluginProv = context.read<PluginProvider>();

    final List<String> defaultLabels = [
      'Accueil',
      'Tâches',
      'Calendrier',
      'Collaborateurs',
      'Messages',
      'Notifications',
      'Library',
      'Projets',
      'Paramètres',
    ];

    final List<String> labels = [
      ...defaultLabels.sublist(0, 8),
      if (pluginProv.isInstalled('stock')) 'Stock',
      if (pluginProv.isInstalled('stock')) 'Commandes',
      defaultLabels.last,
    ];
    return labels[index];
  }
}
