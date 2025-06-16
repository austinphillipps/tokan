import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tokan/plugins/crm/models/opportunity.dart';
import 'package:tokan/main.dart' show AppColors; // For glass colors

class OpportunityProgressCard extends StatelessWidget {
  final Opportunity opportunity;
  final VoidCallback? onTap;

  const OpportunityProgressCard({
    Key? key,
    required this.opportunity,
    this.onTap,
  }) : super(key: key);

  static const List<String> stages = [
    'Prospect',
    'Qualification',
    'Négociation',
    'Gagné',
    'Perdu',
  ];

  @override
  Widget build(BuildContext context) {
    final stageIndex = stages.indexOf(opportunity.stage);
    final progress = stageIndex >= 0
        ? stageIndex / (stages.length - 1)
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(opportunity.name,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                '${NumberFormat.currency(symbol: '€', decimalDigits: 0).format(opportunity.amount)} • '
                '${DateFormat.yMd().format(opportunity.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Theme.of(context).dividerColor,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 4),
              Text(opportunity.stage,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
