// lib/features/dashboard/views/dashboard_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tokan/core/providers/plugin_provider.dart';
import 'package:tokan/core/contract/plugin_contract.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_widget_provider.dart';
import 'manage_dashboard_widgets_sheet.dart';
import '../../../services/update_manager.dart'; // ← UpdateManager
import '../../../main.dart';               // Pour AppTheme, themeNotifier

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    if (Platform.isMacOS || Platform.isWindows) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<UpdateManager>().checkForUpdate(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = themeNotifier.value == AppTheme.light;
    final pluginProv = context.watch<PluginProvider>();
    final installedPlugins = pluginProv.installedPlugins;
    final dashboardProv = context.watch<DashboardWidgetProvider>();

    return Scaffold(
      // Étend le body derrière l'AppBar pour profiter de la transparence
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.widgets),
            tooltip: 'Gérer les widgets',
            color: Colors.white,
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (_) => const ManageDashboardWidgetsSheet(),
            ),
          ),
          StreamBuilder<DateTime>(
            stream: Stream<DateTime>.periodic(
                const Duration(seconds: 1), (_) => DateTime.now()),
            builder: (context, snapshot) {
              final now = snapshot.data ?? DateTime.now();
              final timeStr = DateFormat('HH:mm:ss').format(now);
              final dateStr = DateFormat('EEEE, dd MMM yyyy', 'fr_FR')
                  .format(now);
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeStr,
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: kToolbarHeight + MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Widgets du dashboard
            for (final w in dashboardProv.widgets) w,

            // Extensions installées
            if (installedPlugins.isNotEmpty) ...[
              const Divider(height: 32),
              Text(
                'Extensions installées',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              for (final p in installedPlugins)
                if (p.buildDashboardWidget(context) != null)
                  p.buildDashboardWidget(context)!,
            ],
          ],
        ),
      ),
    );
  }
}
