// lib/shared/interface/interface.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';      // Pour PointerEnterEvent / PointerExitEvent
import 'package:provider/provider.dart';

import '../../core/providers/plugin_provider.dart';
import '../../core/contract/plugin_contract.dart';

import '../../features/dashboard/views/dashboard_screen.dart';
import '../../features/tasks/views/tasks_screen.dart';
import '../../features/calendar/views/calendar_screen.dart';
import '../../features/collaborators/views/collaborators_screen.dart';
import '../../features/chat/views/messages_screen.dart';
import '../../features/notifications/views/notifications_screen.dart';
import '../../features/library/views/library_screen.dart';
import '../../features/projects/views/projects_screen.dart';
import '../../settings/views/settings_screen.dart';

import '../../main.dart'; // Pour AppTheme, themeNotifier et AppColors

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

  void _onMouseEnter(PointerEnterEvent _) {
    _labelTimer?.cancel();
    setState(() => _sidebarExpanded = true);
    _labelTimer = Timer(const Duration(milliseconds: 200), () {
      if (_sidebarExpanded) setState(() => _showLabels = true);
    });
  }

  void _onMouseExit(PointerExitEvent _) {
    _labelTimer?.cancel();
    setState(() {
      _showLabels = false;
      _sidebarExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSequoia = themeNotifier.value == AppTheme.sequoia;
    final isDark    = theme.brightness == Brightness.dark;
    final pluginProv = context.watch<PluginProvider>();

    // 1) Pages "de base"
    final basePages = <Widget>[
      const DashboardScreen(),         // 0
      const TasksPage(),               // 1
      CalendarPage(refreshNotifier: _calendarRefreshNotifier), // 2
      const CollaboratorsPage(),       // 3
      const MessagesPage(),            // 4
      const NotificationsPage(),       // 5 (bottom)
      const LibraryPage(),             // 6 (bottom)
      ProjectsScreen(),                // 7
      const SettingsPage(),            // 8 (bottom)
    ];

    // 2) Plugins installés
    final plugins = pluginProv.installedPlugins;

    // 3) Concaténer pages dans l'ordre souhaité
    final pages = <Widget>[
      // Haut : Accueil..Messages, puis Projets
      basePages[0],
      basePages[1],
      basePages[2],
      basePages[3],
      basePages[4],
      basePages[7],
      // Plugins dynamiques
      for (final p in plugins) p.buildMainScreen(context),
      // Bas fixe : Notifications, Library, Paramètres
      basePages[5],
      basePages[6],
      basePages[8],
    ];

    // Icônes correspondantes
    final icons = <IconData>[
      Icons.home,
      Icons.task_alt,
      Icons.calendar_today,
      Icons.group,
      Icons.message,
      Icons.work,           // Projets
      for (final p in plugins) p.iconData,
      Icons.notifications,
      Icons.library_books,
      Icons.settings,
    ];

    // Labels correspondantes
    final labels = <String>[
      'Accueil',
      'Tâches',
      'Calendrier',
      'Collaborateurs',
      'Messages',
      'Projets',
      for (final p in plugins) p.displayName,
      'Notifications',
      'Library',
      'Paramètres',
    ];

    // Couleurs
    final sidebarBg   = theme.colorScheme.surface;
    final mainBg      = theme.colorScheme.background;
    final dividerColor= theme.colorScheme.onBackground.withOpacity(0.3);
    // Utiliser désormais la couleur glassBackground définie dans AppColors
    final selectedBg  = AppColors.glassHeader;

    Widget sidebar = MouseRegion(
      onEnter: _onMouseEnter,
      onExit: _onMouseExit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _sidebarExpanded ? 180 : 60,
        color: sidebarBg.withOpacity(isSequoia ? 0.6 : 1.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // Items du haut
            for (var i = 0; i < pages.length - 3; i++)
              _buildNavItem(
                iconData: icons[i],
                label: labels[i],
                showLabel: _showLabels,
                isSelected: _selectedIndex == i,
                selectedBg: selectedBg,
                onTap: () => setState(() => _selectedIndex = i),
              ),
            const Spacer(),
            // Items fixes en bas
            for (var i = pages.length - 3; i < pages.length; i++)
              _buildNavItem(
                iconData: icons[i],
                label: labels[i],
                showLabel: _showLabels,
                isSelected: _selectedIndex == i,
                selectedBg: selectedBg,
                onTap: () => setState(() => _selectedIndex = i),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    Widget content = Scaffold(
      backgroundColor: isSequoia ? Colors.transparent : mainBg,
      body: Row(
        children: [
          sidebar,
          VerticalDivider(width: 1, color: dividerColor),
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
    );

    if (isSequoia) {
      return Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/sequoia.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: content,
      );
    }
    return content;
  }

  Widget _buildNavItem({
    required IconData iconData,
    required String label,
    required bool showLabel,
    required bool isSelected,
    required Color selectedBg,
    required VoidCallback onTap,
  }) {
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface;
    return Material(
      color: isSelected ? selectedBg : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Icon(iconData, size: 24, color: color),
              if (showLabel) ...[
                const SizedBox(width: 12),
                Text(label, style: TextStyle(color: color)),
              ] else
                Tooltip(message: label, child: const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}
