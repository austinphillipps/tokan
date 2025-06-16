// lib/plugins/crm/screens/opportunity_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tokan/main.dart'; // pour AppColors
import 'package:tokan/plugins/crm/models/opportunity.dart';
import 'package:tokan/plugins/crm/providers/opportunity_provider.dart';
import 'package:tokan/plugins/crm/screens/opportunity_form_screen.dart';

class OpportunityDetailScreen extends StatefulWidget {
  final String opportunityId;
  const OpportunityDetailScreen({Key? key, required this.opportunityId})
      : super(key: key);

  @override
  State<OpportunityDetailScreen> createState() =>
      _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState extends State<OpportunityDetailScreen> {
  Opportunity? _opp;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOpp();
  }

  Future<void> _loadOpp() async {
    final opp = await context
        .read<OpportunityProvider>()
        .fetchById(widget.opportunityId);
    setState(() {
      _opp = opp;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: AppColors.glassHeader,
        elevation: 0,
        title: const Text(
          'Détail Opportunité',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_loading && _opp != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (_) => OpportunityFormScreen(
                      opportunityId: widget.opportunityId,
                    ),
                  ),
                )
                    .then((_) => _loadOpp()); // recharger après édition
              },
            ),
        ],
      ),

      body: SafeArea(
        child: Container(
          color: AppColors.glassBackground,
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _opp == null
              ? const Center(child: Text('Opportunité introuvable'))
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Intitulé : ${_opp!.name}',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Montant : €${_opp!.amount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text('Phase : ${_opp!.stage}',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(
                'Créée le : '
                    '${_opp!.createdAt.day}/${_opp!.createdAt.month}/${_opp!.createdAt.year}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Supprimer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () async {
                    await context
                        .read<OpportunityProvider>()
                        .delete(widget.opportunityId);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}