// lib/plugins/crm/screens/pipeline_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:tokan/main.dart'; // pour AppColors
import '../providers/opportunity_provider.dart';
import '../models/opportunity.dart';
import 'opportunity_detail_screen.dart';
import 'opportunity_form_screen.dart';

class PipelineScreen extends StatefulWidget {
  const PipelineScreen({Key? key}) : super(key: key);

  @override
  State<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends State<PipelineScreen> {
  bool _showPanel = false;
  String? _panelOppId;

  /// Ouvre le panneau : [opportunityId]==null → formulaire, sinon détail
  void _openPanel({String? opportunityId}) {
    setState(() {
      _panelOppId = opportunityId;
      _showPanel = true;
    });
  }

  /// Ferme le panneau
  void _closePanel() {
    setState(() {
      _showPanel = false;
      _panelOppId = null;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OpportunityProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OpportunityProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pipeline'),
        automaticallyImplyLeading: false,
        leading: const SizedBox.shrink(),
      ),
      body: Container(
        color: AppColors.glassBackground,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // hauteur disponible pour nos colonnes
            final height = constraints.maxHeight;

            if (prov.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Stack(
              children: [
                // --- 1) Kanban horizontal, prend toute la hauteur ---
                SizedBox(
                  height: height,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <String>[
                        'Prospect',
                        'Qualification',
                        'Négociation',
                        'Gagné',
                        'Perdu',
                      ].map((stage) {
                        final items = prov.opportunities
                            .where((o) => o.stage == stage)
                            .toList();

                        return SizedBox(
                          width: 280,
                          height: height,
                          child: Card(
                            margin: const EdgeInsets.all(8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                              side: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // En-tête de colonne
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.glassHeader,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4)),
                                  ),
                                  child: Text(
                                    stage,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                // Liste des opportunités
                                Expanded(
                                  child: items.isEmpty
                                      ? const Center(child: Text('—'))
                                      : ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: items.length,
                                    itemBuilder: (_, i) {
                                      final opp = items[i];
                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: ListTile(
                                          title: Text(opp.name),
                                          subtitle: Text(
                                            '${NumberFormat.currency(symbol: '€', decimalDigits: 0).format(opp.amount)} • '
                                                '${DateFormat.yMd().format(opp.createdAt)}',
                                          ),
                                          onTap: () => _openPanel(
                                              opportunityId: opp.id),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // --- 2) Overlay pour fermer au clic en dehors ---
                if (_showPanel)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _closePanel,
                      behavior: HitTestBehavior.translucent,
                      child: Container(color: Colors.black26),
                    ),
                  ),

                // --- 3) Panneau latéral glissant depuis la droite ---
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  top: 0,
                  bottom: 0,
                  right: _showPanel ? 0 : -MediaQuery.of(context).size.width * 0.75,
                  width: MediaQuery.of(context).size.width * 0.25,
                  child: Material(
                    elevation: 16,
                    color: AppColors.glassBackground,
                    child: SafeArea(
                      child: _panelOppId == null
                          ? OpportunityFormScreen(onSaved: _closePanel)
                          : OpportunityDetailScreen(opportunityId: _panelOppId!),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: !_showPanel
          ? FloatingActionButton(
        tooltip: 'Nouvelle opportunité',
        child: const Icon(Icons.add),
        onPressed: () => _openPanel(),
      )
          : null,
    );
  }
}