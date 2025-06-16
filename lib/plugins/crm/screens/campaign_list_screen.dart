// lib/plugins/crm/screens/campaign_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tokan/main.dart'; // pour AppColors
import '../providers/campaign_provider.dart';
import '../models/campaign.dart';
import 'campaign_form_screen.dart';
import 'campaign_detail_screen.dart';

class CampaignListScreen extends StatefulWidget {
  const CampaignListScreen({Key? key}) : super(key: key);

  @override
  _CampaignListScreenState createState() => _CampaignListScreenState();
}

class _CampaignListScreenState extends State<CampaignListScreen> {
  bool _showPanel = false;
  String? _panelCampaignId;

  /// Ouvre le panneau (form si [campaignId]==null, sinon détail)
  void _openPanel({String? campaignId}) {
    setState(() {
      _panelCampaignId = campaignId;
      _showPanel = true;
    });
  }

  /// Ferme le panneau
  void _closePanel() {
    setState(() {
      _showPanel = false;
      _panelCampaignId = null;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.read<CampaignProvider>().fetchAll(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CampaignProvider>();
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // 1) Liste des campagnes
          if (prov.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (prov.campaigns.isEmpty)
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _openPanel(campaignId: null),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter votre première campagne'),
              ),
            )
          else
            ListView.builder(
              itemCount: prov.campaigns.length,
              itemBuilder: (_, i) {
                final c = prov.campaigns[i];
                return ListTile(
                  title: Text(c.name),
                  subtitle: Text('${c.status} • ${c.startDate}'),
                  onTap: () => _openPanel(campaignId: c.id),
                );
              },
            ),

          // 2) Overlay pour fermer le panneau au clic à l'extérieur
          if (_showPanel)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closePanel,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.black26),
              ),
            ),

          // 3) Panneau latéral glissant depuis la droite
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            top: 0,
            bottom: 0,
            right: _showPanel ? 0 : -screenWidth * 0.75,
            width: screenWidth * 0.25,
            child: Material(
              elevation: 16,
              color: AppColors.glassBackground,
              child: SafeArea(
                child: _panelCampaignId == null
                    ? CampaignFormScreen(onSaved: _closePanel)
                    : CampaignDetailScreen(campaignId: _panelCampaignId!),
              ),
            ),
          ),
        ],
      ),

      // FAB pour créer une campagne (caché si panneau ouvert)
      floatingActionButton: !_showPanel
          ? FloatingActionButton(
        tooltip: 'Nouvelle campagne',
        child: const Icon(Icons.campaign),
        onPressed: () => _openPanel(campaignId: null),
      )
          : null,
    );
  }
}