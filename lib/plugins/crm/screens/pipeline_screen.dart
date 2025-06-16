// lib/plugins/crm/screens/pipeline_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tokan/main.dart'; // pour AppColors
import '../providers/opportunity_provider.dart';
import '../widgets/opportunity_progress_card.dart';
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
            if (prov.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Stack(
              children: [
                // --- 1) Liste moderne axée sur la progression ---
                ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: prov.opportunities.length,
                  itemBuilder: (_, i) {
                    final opp = prov.opportunities[i];
                    return OpportunityProgressCard(
                      opportunity: opp,
                      onTap: () => _openPanel(opportunityId: opp.id),
                    );
                  },
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