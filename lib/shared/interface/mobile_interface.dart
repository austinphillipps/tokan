// lib/shared/interface/mobile_interface.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/providers/plugin_provider.dart';
import '../../features/dashboard/views/dashboard_screen.dart';
import '../../features/tasks/views/tasks_screen.dart';
import '../../features/collaborators/views/collaborators_screen.dart';
import '../../features/notifications/views/notifications_screen.dart';
import '../../features/library/views/library_screen.dart';
import '../../features/projects/views/projects_screen.dart';
import '../../settings/views/settings_screen.dart';
import '../../features/notifications/services/notification_service.dart';
import '../../main.dart'; // Pour AppColors

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({Key? key}) : super(key: key);

  @override
  _MobileHomeScreenState createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  int _selectedIndex = 0;
  int _bottomIndex = 0;
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

  @override
  Widget build(BuildContext context) {
    final pluginProv = context.watch<PluginProvider>();

    final basePages = <Widget>[
      const DashboardScreen(),
      const TasksPage(),
      const CollaboratorsPage(),
      const NotificationsPage(),
      const LibraryPage(),
      ProjectsScreen(),
      const SettingsPage(),
    ];

    final plugins = pluginProv.installedPlugins;

    final pages = <Widget>[
      basePages[0], // Dashboard
      basePages[1], // Tasks
      basePages[2], // Collaborators
      basePages[5], // Projects
      for (final p in plugins) p.buildMainScreen(context),
      basePages[3], // Notifications
      basePages[4], // Library
      basePages[6], // Settings
    ];

    final icons = <IconData>[
      Icons.home,
      Icons.task_alt,
      Icons.group,
      Icons.work,
      for (final p in plugins) p.iconData,
      Icons.notifications,
      Icons.library_books,
      Icons.settings,
    ];

    final labels = <String>[
      'Accueil',
      'Tâches',
      'Collaborateurs',
      'Projets',
      for (final p in plugins) p.displayName,
      'Notifications',
      'Library',
      'Paramètres',
    ];

    final notifIndex = 4 + plugins.length;
    final libraryIndex = notifIndex + 1;
    final settingsIndex = notifIndex + 2;

    final bottomItemsCount = notifIndex;
    final showBottomNav =
        _selectedIndex < bottomItemsCount || _selectedIndex == libraryIndex;

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            child: Container(
              color: AppColors.glassHeader,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: _buildNotificationsIcon(Icons.notifications),
                    onPressed: () => setState(() => _selectedIndex = notifIndex),
                  ),
                  IconButton(
                    icon: const Icon(Icons.library_books),
                    onPressed: () => setState(() => _selectedIndex = libraryIndex),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => setState(() => _selectedIndex = settingsIndex),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: showBottomNav
          ? BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (i) => setState(() {
          _selectedIndex = i;
          _bottomIndex = i;
        }),
        type: BottomNavigationBarType.fixed,
        items: [
          for (int i = 0; i < bottomItemsCount; i++)
            BottomNavigationBarItem(
              icon: _buildIcon(i, icons[i]),
              label: labels[i],
            ),
        ],
      )
          : null,
    );
  }

  Widget _buildIcon(int index, IconData icon) {
    if (icon == Icons.notifications) {
      return _buildNotificationsIcon(icon);
    }
    return Icon(icon);
  }

  Widget _buildNotificationsIcon(IconData icon) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Icon(icon);

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
            if (count == 0) return Icon(icon);
            return Stack(
              children: [
                Icon(icon),
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
                      '$count',
                      style:
                      const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}