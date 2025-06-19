// lib/shared/interface/interface.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/widgets/profile_info_dialog.dart';

import '../../main.dart'; // Pour AppTheme, themeNotifier et AppColors
import '../../features/notifications/services/notification_service.dart';

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
    _checkProfileCompletion();
  }

  Future<void> _checkProfileCompletion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data() ?? {};
    final first = (data['firstName'] ?? '').toString().trim();
    final last = (data['lastName'] ?? '').toString().trim();
    final phone = (data['phoneNumber'] ?? '').toString().trim();
    if (first.isEmpty || last.isEmpty || phone.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const ProfileInfoDialog(),
        );
      });
    }
  }

  @override
  void dispose() {
    _notifService.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarExpanded = !_sidebarExpanded;
      if (!_sidebarExpanded) {
        _showLabels = false; // Hide labels immediately when collapsing
      }
    });
    if (_sidebarExpanded) {
      // Delay showing labels until the expansion animation completes
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() => _showLabels = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSequoia = themeNotifier.value == AppTheme.sequoia;
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
      Icons.work, // Projets
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

    Widget sidebar = AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _sidebarExpanded ? 180 : 60,
        color: sidebarBg.withOpacity(isSequoia ? 0.6 : 1.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // Items du haut
            for (var i = 0; i < pages.length - 3; i++)
              i == 4
                  ? _buildMessagesNavItem(
                index: i,
                iconData: icons[i],
                label: labels[i],
              )
                  : _buildNavItem(
                iconData: icons[i],
                label: labels[i],
                showLabel: _showLabels,
                isSelected: _selectedIndex == i,
                onTap: () => setState(() => _selectedIndex = i),
              ),
            const Spacer(),
            // Items fixes en bas
            for (var i = pages.length - 3; i < pages.length; i++)
              i == pages.length - 3
                  ? _buildNotificationsNavItem(
                index: i,
                iconData: icons[i],
                label: labels[i],
              )
                  : _buildNavItem(
                iconData: icons[i],
                label: labels[i],
                showLabel: _showLabels,
                isSelected: _selectedIndex == i,
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
      );

    Widget content = Scaffold(
      backgroundColor: isSequoia ? Colors.transparent : mainBg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _buildMessagesNavItem({
    required int index,
    required IconData iconData,
    required String label,
  }) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return _buildNavItem(
        iconData: iconData,
        label: label,
        showLabel: _showLabels,
        isSelected: _selectedIndex == index,
        onTap: () => setState(() => _selectedIndex = index),
      );
    }

    final convStream = FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: convStream,
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        int count = 0;
        for (final d in docs) {
          final data = d.data() as Map<String, dynamic>;
          final unread = List<String>.from(data['unreadBy'] ?? []);
          if (unread.contains(uid)) count++;
        }
        return _buildNavItem(
          iconData: iconData,
          label: label,
          showLabel: _showLabels,
          isSelected: _selectedIndex == index,
          badgeCount: count > 0 ? count : null,
          onTap: () => setState(() => _selectedIndex = index),
        );
      },
    );
  }

  Widget _buildNotificationsNavItem({
    required int index,
    required IconData iconData,
    required String label,
  }) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return _buildNavItem(
        iconData: iconData,
        label: label,
        showLabel: _showLabels,
        isSelected: _selectedIndex == index,
        onTap: () => setState(() => _selectedIndex = index),
      );
    }

    final pendingStream = FirebaseFirestore.instance
        .collection('collaborations')
        .where('to', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: pendingStream,
      builder: (ctx, pendSnap) {
        final pending = pendSnap.data?.size ?? 0;
        final notifStream = FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', isEqualTo: uid)
            .where('read', isEqualTo: false)
            .snapshots();

        return StreamBuilder<QuerySnapshot>(
          stream: notifStream,
          builder: (ctx2, notifSnap) {
            final count = (notifSnap.data?.size ?? 0) + pending;
            return _buildNavItem(
              iconData: iconData,
              label: label,
              showLabel: _showLabels,
              isSelected: _selectedIndex == index,
              badgeCount: count > 0 ? count : null,
              onTap: () => setState(() => _selectedIndex = index),
            );
          },
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData iconData,
    required String label,
    required bool showLabel,
    required bool isSelected,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return _SidebarButton(
      iconData: iconData,
      label: label,
      showLabel: showLabel,
      isSelected: isSelected,
      onTap: onTap,
      badgeCount: badgeCount,
    );
  }
}

class _SidebarButton extends StatefulWidget {
  final IconData iconData;
  final String label;
  final bool showLabel;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badgeCount;

  const _SidebarButton({
    Key? key,
    required this.iconData,
    required this.label,
    required this.showLabel,
    required this.isSelected,
    required this.onTap,
    this.badgeCount,
  }) : super(key: key);

  @override
  State<_SidebarButton> createState() => _SidebarButtonState();
}

class _SidebarButtonState extends State<_SidebarButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalColor = colorScheme.onSurface.withOpacity(0.6);
    final hoverColor = colorScheme.onSurface;
    final selectedColor = colorScheme.primary;
    const hoverBg = Color(0xFFE5E5EA);
    const selectedBg = Color(0xFFE5E5EA);

    final fgColor = widget.isSelected
        ? selectedColor
        : (_hovering ? hoverColor : normalColor);
    final bgColor = widget.isSelected
        ? selectedBg
        : (_hovering ? hoverBg : Colors.transparent);

    Widget label = widget.showLabel
        ? Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'San Francisco',
                fontFamilyFallback: ['Helvetica Neue'],
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        : Tooltip(message: widget.label, child: const SizedBox.shrink());

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        height: 48,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Row(
            children: [
              Stack(
                children: [
                  Icon(widget.iconData, size: 24, color: fgColor),
                  if (widget.badgeCount != null && widget.badgeCount! > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${widget.badgeCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              if (widget.showLabel) label,
            ],
          ),
        ),
      ),
    );
  }
}

