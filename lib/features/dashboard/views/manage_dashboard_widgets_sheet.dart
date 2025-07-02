import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/dashboard_widget_provider.dart';
import '../widgets/project_progress_widget.dart';

/// Bottom sheet allowing the user to enable or disable dashboard widgets.
class ManageDashboardWidgetsSheet extends StatefulWidget {
  const ManageDashboardWidgetsSheet({Key? key}) : super(key: key);

  @override
  State<ManageDashboardWidgetsSheet> createState() => _ManageDashboardWidgetsSheetState();
}

class _ManageDashboardWidgetsSheetState extends State<ManageDashboardWidgetsSheet> {
  bool _showProjectProgress = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DashboardWidgetProvider>();
    _showProjectProgress = provider.hasWidgetOfType<ProjectProgressWidget>();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Widgets du dashboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          CheckboxListTile(
            title: const Text('Progression des projets'),
            value: _showProjectProgress,
            onChanged: (val) {
              setState(() => _showProjectProgress = val ?? false);
              final provider = context.read<DashboardWidgetProvider>();
              if (val == true) {
                provider.addWidget(const ProjectProgressWidget());
              } else {
                provider.removeWidgetOfType<ProjectProgressWidget>();
              }
            },
          ),
        ],
      ),
    );
  }
}