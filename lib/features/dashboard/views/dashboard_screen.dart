import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tokan/core/providers/plugin_provider.dart';
import 'package:tokan/core/contract/plugin_contract.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_widget_provider.dart';
import 'manage_dashboard_widgets_sheet.dart';
import '../../../services/update_service.dart';    // ← UpdateService
import '../../../main.dart' hide UpdateService; // Pour AppTheme, AppColors, themeNotifier // Pour AppTheme, AppColors, themeNotifier

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    if (Platform.isMacOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        UpdateService.checkForUpdate(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = themeNotifier.value == AppTheme.light;
    final pluginProv = context.watch<PluginProvider>();
    final installedPlugins = pluginProv.installedPlugins;
    final dashboardProv = context.watch<DashboardWidgetProvider>();

    // Fond “white glass” sous le scroll
    return Container(
      color: isLight
          ? AppColors.whiteGlassBackground
          : AppColors.glassBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne date / gestion widgets
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StreamBuilder<DateTime>(
                  stream: Stream<DateTime>.periodic(
                      const Duration(seconds: 1), (_) => DateTime.now()),
                  builder: (context, snapshot) {
                    final now = snapshot.data ?? DateTime.now();
                    final time = DateFormat('HH:mm:ss').format(now);
                    final date = DateFormat('dd MMM yyyy').format(now);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isLight
                            ? AppColors.whiteGlassHeader
                            : AppColors.glassHeader,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$time \u2022 $date',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.widgets),
                  tooltip: 'Gérer les widgets',
                  color: theme.iconTheme.color,
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    builder: (_) => const ManageDashboardWidgetsSheet(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tes widgets
            for (final w in dashboardProv.widgets) w,

            // Extensions
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
