import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tokan/core/contract/plugin_contract.dart';

import '../providers/contact_provider.dart';
import '../providers/opportunity_provider.dart';
import '../providers/quote_provider.dart';
import '../providers/campaign_provider.dart';
import '../providers/support_ticket_provider.dart';

import '../widgets/crm_kpi_card.dart';
import '../screens/contact_list_screen.dart';
import '../screens/pipeline_screen.dart';
import '../screens/quote_list_screen.dart';
import '../screens/campaign_list_screen.dart';
import '../screens/support_list_screen.dart';
import '../screens/dashboard_ai_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/assistant_ia_screen.dart';
import '../screens/automatisation_screen.dart';
import '../screens/com_omni_screen.dart';
import '../screens/integration_screen.dart';
import '../screens/collaboration_screen.dart';
import '../screens/security_screen.dart';

class CrmPlugin implements PluginContract {
  @override
  String get id => 'crm';

  @override
  String get displayName => 'CRM';

  @override
  IconData get iconData => Icons.business_center;

  /// Full-screen scaffold if you navigate to CRM as a standalone page
  @override
  Widget buildMainScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(displayName)),
      body: buildContent(context),
    );
  }

  /// Embed-friendly content (only the inner view, no Scaffold/AppBar)
  @override
  Widget buildContent(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => OpportunityProvider()),
        ChangeNotifierProvider(create: (_) => QuoteProvider()),
        ChangeNotifierProvider(create: (_) => CampaignProvider()),
        ChangeNotifierProvider(create: (_) => SupportTicketProvider()),
      ],
      child: const _CrmView(),
    );
  }

  @override
  Widget? buildDashboardWidget(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        CrmKpiCard(title: 'Opportunités ouvertes', value: '12'),
        SizedBox(height: 16),
        CrmKpiCard(title: 'CA Pipeline', value: '€ 45 000'),
      ],
    );
  }
}

class _CrmView extends StatefulWidget {
  const _CrmView({Key? key}) : super(key: key);

  @override
  State<_CrmView> createState() => _CrmViewState();

  static const _mainTabs = [
    'Commercial',
    'Mktg & Support',
    'Insights',
    'Admin',
  ];

  // Map each main tab to an icon displayed above the title
  static const Map<String, IconData> _mainIcons = {
    'Commercial': Icons.business_center,
    'Mktg & Support': Icons.campaign,
    'Insights': Icons.insights,
    'Admin': Icons.admin_panel_settings,
  };

  static const Map<String, List<String>> _subTabs = {
    'Commercial': ['Contacts', 'Pipeline', 'Devis'],
    'Mktg & Support': ['Campagnes', 'Support'],
    'Insights': [
      'Dashboard AI',
      'Analytics',
      'Assistant IA',
      'Automatisation',
      'Com. Omni.',
    ],
    'Admin': ['Intégrations', 'Collab.', 'Sécurité'],
  };
}

class _CrmViewState extends State<_CrmView> with TickerProviderStateMixin {
  late final TabController _mainCtrl;
  late TabController _subCtrl;

  @override
  void initState() {
    super.initState();
    _mainCtrl = TabController(length: _CrmView._mainTabs.length, vsync: this)
      ..addListener(_onMainTabChanged);
    _initSubController();
  }

  void _onMainTabChanged() {
    _initSubController();
    setState(() {});
  }

  void _initSubController() {
    final main = _CrmView._mainTabs[_mainCtrl.index];
    _subCtrl = TabController(
      length: _CrmView._subTabs[main]!.length,
      vsync: this,
    )..addListener(() => setState(() {}));
  }

  String get _currentMain => _CrmView._mainTabs[_mainCtrl.index];

  @override
  void dispose() {
    _mainCtrl.dispose();
    _subCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subs = _CrmView._subTabs[_currentMain]!;

    return Column(
      children: [
        // Main tabs with icons
        TabBar(
          controller: _mainCtrl,
          tabs: _CrmView._mainTabs.map((t) => Tab(
            icon: Icon(_CrmView._mainIcons[t]),
            text: t,
          )).toList(),
        ),
        // Sub-tabs + content
        Expanded(
          child: Column(
            children: [
              TabBar(
                controller: _subCtrl,
                isScrollable: true,
                tabs: subs.map((t) => Tab(text: t)).toList(),
              ),
              Expanded(
                child: TabBarView(
                  controller: _subCtrl,
                  children: subs.map((label) {
                    switch (_currentMain) {
                      case 'Commercial':
                        if (label == 'Contacts') return const ContactListScreen();
                        if (label == 'Pipeline') return const PipelineScreen();
                        if (label == 'Devis') return const QuoteListScreen();
                        break;
                      case 'Mktg & Support':
                        if (label == 'Campagnes') return const CampaignListScreen();
                        if (label == 'Support') return const SupportListScreen();
                        break;
                      case 'Insights':
                        if (label == 'Dashboard AI') return const DashboardAiScreen();
                        if (label == 'Analytics') return const AnalyticsScreen();
                        if (label == 'Assistant IA') return const AssistantIaScreen();
                        if (label == 'Automatisation') return const AutomatisationScreen();
                        if (label == 'Com. Omni.') return const ComOmniScreen();
                        break;
                      case 'Admin':
                        if (label == 'Intégrations') return const IntegrationScreen();
                        if (label == 'Collab.') return const CollaborationScreen();
                        if (label == 'Sécurité') return const SecurityScreen();
                        break;
                    }
                    return const SizedBox.shrink();
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget? _buildFab(BuildContext context) {
    final subs = _CrmView._subTabs[_currentMain]!;
    final label = subs[_subCtrl.index];
    if (_currentMain == 'Mktg & Support' && label == 'Campagnes') {
      // NOTE: no CampaignFormScreen class exists, remove or replace with correct one
      return null;
    }
    return null;
  }
}