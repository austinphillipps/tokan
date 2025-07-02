// lib/plugins/crm/widgets/crm_kpi_card.dart

import 'package:flutter/material.dart';

class CrmKpiCard extends StatelessWidget {
  final String title;
  final String value;

  const CrmKpiCard({
    Key? key,
    required this.title,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.titleMedium,     // remplace subtitle1
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.headlineMedium,  // remplace headline5
        ),
      ],
    );
  }
}
