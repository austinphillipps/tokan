// lib/plugins/crm/screens/campaign_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tokan/main.dart'; // pour AppColors

import '../models/campaign.dart';
import '../providers/campaign_provider.dart';
import 'campaign_form_screen.dart';

class CampaignDetailScreen extends StatefulWidget {
  final String campaignId;
  const CampaignDetailScreen({Key? key, required this.campaignId})
      : super(key: key);

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  Campaign? _campaign;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    context
        .read<CampaignProvider>()
        .fetchById(widget.campaignId)
        .then((c) {
      setState(() {
        _campaign = c;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.glassBackground,
        appBar: AppBar(
          backgroundColor: AppColors.glassHeader,
          elevation: 0,
          title: const Text('Campagne'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_campaign == null) {
      return Scaffold(
        backgroundColor: AppColors.glassBackground,
        appBar: AppBar(
          backgroundColor: AppColors.glassHeader,
          elevation: 0,
          title: const Text('Campagne'),
        ),
        body: const Center(child: Text('Campagne introuvable')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.glassBackground,
      appBar: AppBar(
        backgroundColor: AppColors.glassHeader,
        elevation: 0,
        title: Text(_campaign!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CampaignFormScreen(campaignId: widget.campaignId),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () async {
              await context.read<CampaignProvider>().delete(widget.campaignId);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_campaign!.description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Text(
            'Dates : ${DateFormat.yMd().format(_campaign!.startDate)} – '
                '${DateFormat.yMd().format(_campaign!.endDate)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text('Statut : ${_campaign!.status}', style: Theme.of(context).textTheme.bodyMedium),
        ]),
      ),
    );
  }
}