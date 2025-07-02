// lib/shared/interface/interface.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/providers/plugin_provider.dart';
import 'package:tokan/core/contract/plugin_contract.dart';

import '../../features/dashboard/views/dashboard_screen.dart';
import '../../features/tasks/views/tasks_screen.dart';
import '../../features/calendar/views/calendar_screen.dart';
import '../../features/collaborators/views/collaborators_screen.dart';
import '../../features/chat/views/messages_screen.dart';
import '../../features/notifications/views/notifications_screen.dart';
import '../../features/library/views/library_screen.dart';
import '../../features/projects/views/projects_screen.dart';
import '../../settings/views/settings_screen.dart';
import '../../features/notifications/services/notification_service.dart';

import 'dart:ui';
import '../../main.dart'; // Pour AppTheme, themeNotifier et AppColors

/// Widget réutilisable pour effet "glass" (blanc/translucide + flou)
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  const GlassContainer({Key? key, this.width, this.height, this.borderRadius, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Couleur selon thème : blanc translucide en light, verre noir en dark/sequoia
    final color = (theme.brightness == Brightness.light && themeNotifier.value != AppTheme.sequoia)
        ? AppColors.whiteGlassBackground
        : AppColors.glassBackground;
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            // vous pouvez ajouter une bordure ou ombre ici
          ),
          child: child,
        ),
      ),
    );
  }
} // Pour AppTheme, themeNotifier et AppColors

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _sidebarExpanded = true;
  bool _showLabels = true;
  final ValueNotifier<int> _calendarRefreshNotifier = ValueNotifier<int>(0);
  final NotificationService _notifService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notifService.init();
  }

  @override
  void dispose() {
    _notifService.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarExpanded = !_sidebarExpanded;
      if (!_sidebarExpanded) _showLabels = false;
    });
    if (_sidebarExpanded) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _showLabels = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSequoia = themeNotifier.value == AppTheme.sequoia;
    final pluginProv = context.watch<PluginProvider>();

    // 1) Pages de base
    final basePages = <Widget>[
      const DashboardScreen(),
      const TasksPage(),
      CalendarPage(refreshNotifier: _calendarRefreshNotifier),
      const CollaboratorsPage(),
      const MessagesPage(),
      const NotificationsPage(),
      const LibraryPage(),
      ProjectsScreen(),
      const SettingsPage(),
    ];

    // 2) Plugins installés
    final plugins = pluginProv.installedPlugins;

    // 3) Concaténation
    final pages = <Widget>[
      basePages[0],
      basePages[1],
      basePages[2],
      basePages[3],
      basePages[4],
      basePages[7],
      for (final p in plugins) p.buildMainScreen(context),
      basePages[5],
      basePages[6],
      basePages[8],
    ];

    // Helper SVG avec couleur optionnelle
    Widget _svg(String name, {Color? color}) => SvgPicture.asset(
      'assets/icons/$name',
      width: 24,
      height: 24,
      color: color,
    );

    // Couleurs communes
    final bool isLight = theme.brightness == Brightness.light && !isSequoia;
    final iconColor = isLight ? Colors.white : Colors.white; // always white for menu
    final navItemColor = isLight ? Colors.white : Theme.of(context).colorScheme.onSurface;

    // Icônes de la barre
    final icons = <Widget>[
      _svg('dashboard.svg'),
      _svg('tasks.svg'),
      _svg('calendar.svg'),
      _svg('collaborators.svg'),
      _svg('messages.svg'),
      _svg('projects.svg'),
      for (final p in plugins) Icon(p.iconData),
      _svg('notifications.svg', color: iconColor),
      _svg('library.svg',      color: iconColor),
      _svg('settings.svg',     color: iconColor),
    ];

    // Labels
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
    final sidebarBg = theme.colorScheme.surface;
    // couleur du contour vertical de la sidebar
    final dividerColor = isLight
        ? Colors.white.withOpacity(0.3)  // blanc translucide en light
        : theme.colorScheme.onBackground.withOpacity(0.3);
    // couleur du survol et état actif selon thème clair ou non
    final selectedBg = isLight
        ? AppColors.whiteGlassBackground // blanc translucide en clair
        : AppColors.glassHeader;

    Widget sidebar = Stack(
      children: [
        // Fond flou du menu
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: _sidebarExpanded ? 180 : 60,
              height: double.infinity,
              decoration: BoxDecoration(
                color: (theme.brightness == Brightness.light && !isSequoia)
                    ? Colors.white.withOpacity(0.8)
                    : sidebarBg.withOpacity(0.6),
              ),
            ),
          ),
        ),
        // Contenu de la sidebar
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _sidebarExpanded ? 180 : 60,
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              for (var i = 0; i < pages.length - 3; i++)
                i == 4
                    ? _buildMessagesNavItem(
                  index: i,
                  icon: icons[i],
                  label: labels[i],
                  selectedBg: selectedBg,
                )
                    : _buildNavItem(
                  icon: icons[i],
                  label: labels[i],
                  showLabel: _showLabels,
                  isSelected: _selectedIndex == i,
                  selectedBg: selectedBg,
                  onTap: () => setState(() => _selectedIndex = i),
                ),
              const Spacer(),
              for (var i = pages.length - 3; i < pages.length; i++)
                i == pages.length - 3
                    ? _buildNotificationsNavItem(
                  index: i,
                  icon: icons[i],
                  label: labels[i],
                  selectedBg: selectedBg,
                )
                    : _buildNavItem(
                  icon: icons[i],
                  label: labels[i],
                  showLabel: _showLabels,
                  isSelected: _selectedIndex == i,
                  selectedBg: selectedBg,
                  onTap: () => setState(() => _selectedIndex = i),
                ),
              InkWell(
                onTap: _toggleSidebar,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    _sidebarExpanded ? Icons.chevron_left : Icons.chevron_right,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );

    // Contenu principal avec fond Sequoia
    Widget content = Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sidebar,
          VerticalDivider(width: 1, color: dividerColor),
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
    );

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

  Widget _buildMessagesNavItem({
    required int index,
    required Widget icon,
    required String label,
    required Color selectedBg,
  }) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return _buildNavItem(
        icon: icon,
        label: label,
        showLabel: _showLabels,
        isSelected: _selectedIndex == index,
        selectedBg: selectedBg,
        onTap: () => setState(() => _selectedIndex = index),
      );
    }

    final convStream = FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: convStream,
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        int count = 0;
        for (final d in docs) {
          final data = d.data();
          final unread = List<String>.from(data['unreadBy'] ?? []);
          if (unread.contains(uid)) count++;
        }
        return _buildNavItem(
          icon: icon,
          label: label,
          showLabel: _showLabels,
          isSelected: _selectedIndex == index,
          selectedBg: selectedBg,
          badgeCount: count > 0 ? count : null,
          onTap: () => setState(() => _selectedIndex = index),
        );
      },
    );
  }

  Widget _buildNotificationsNavItem({
    required int index,
    required Widget icon,
    required String label,
    required Color selectedBg,
  }) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return _buildNavItem(
        icon: icon,
        label: label,
        showLabel: _showLabels,
        isSelected: _selectedIndex == index,
        selectedBg: selectedBg,
        onTap: () => setState(() => _selectedIndex = index),
      );
    }

    final pendingStream = FirebaseFirestore.instance
        .collection('collaborations')
        .where('to', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: pendingStream,
      builder: (ctx, pendSnap) {
        final pending = pendSnap.data?.size ?? 0;
        final notifStream = FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', isEqualTo: uid)
            .where('read', isEqualTo: false)
            .snapshots();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: notifStream,
          builder: (ctx2, notifSnap) {
            final count = (notifSnap.data?.size ?? 0) + pending;
            return _buildNavItem(
              icon: icon,
              label: label,
              showLabel: _showLabels,
              isSelected: _selectedIndex == index,
              selectedBg: selectedBg,
              badgeCount: count > 0 ? count : null,
              onTap: () => setState(() => _selectedIndex = index),
            );
          },
        );
      },
    );
  }

  Widget _buildNavItem({
    required Widget icon,
    required String label,
    required bool showLabel,
    required bool isSelected,
    required Color selectedBg,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    final bool isLight = Theme.of(context).brightness == Brightness.light && themeNotifier.value != AppTheme.sequoia;
    // couleur des icônes pour menu en light: noir
    final iconColor = isLight ? Colors.black : Colors.white;
    // couleur du texte dans la sidebar et nav
    final navItemColor = isLight ? Colors.black : Theme.of(context).colorScheme.onSurface;
    // couleur des icônes et textes
    final itemColor = isLight ? Colors.black : Theme.of(context).colorScheme.onSurface;
    return Material(
      color: isSelected ? selectedBg : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: selectedBg,
        splashColor: selectedBg.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Stack(
                children: [
                  IconTheme(
                    data: IconThemeData(color: itemColor, size: 24),
                    child: icon,
                  ),
                  if (badgeCount != null && badgeCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              if (showLabel) ...[
                const SizedBox(width: 12),
                Text(
                  label,
                  style:
                  TextStyle(color: itemColor, fontWeight: FontWeight.w600),
                ),
              ] else
                Tooltip(message: label, child: const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}
