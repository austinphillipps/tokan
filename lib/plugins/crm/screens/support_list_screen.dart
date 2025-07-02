// lib/plugins/crm/screens/support_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tokan/main.dart'; // AppColors
import '../providers/support_ticket_provider.dart';
import '../models/support_ticket.dart';
import 'support_detail_screen.dart';
import 'support_form_screen.dart';

class SupportListScreen extends StatefulWidget {
  const SupportListScreen({Key? key}) : super(key: key);

  @override
  _SupportListScreenState createState() => _SupportListScreenState();
}

class _SupportListScreenState extends State<SupportListScreen> {
  bool _showPanel = false;
  String? _panelTicketId; // null → form, non-null → détail

  /// Ouvre le panneau (form si [ticketId]==null, sinon détail)
  void _openPanel({String? ticketId}) {
    setState(() {
      _panelTicketId = ticketId;
      _showPanel = true;
    });
  }

  /// Ferme le panneau
  void _closePanel() {
    setState(() {
      _showPanel = false;
      _panelTicketId = null;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportTicketProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ticketsProv = context.watch<SupportTicketProvider>();
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('Tickets de support')),
      body: Stack(
        children: [
          // 1) La liste principale
          if (ticketsProv.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (ticketsProv.tickets.isEmpty)
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _openPanel(ticketId: null),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter votre premier ticket'),
              ),
            )
          else
            ListView.separated(
              itemCount: ticketsProv.tickets.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final t = ticketsProv.tickets[i];
                return ListTile(
                  title: Text(t.title),
                  subtitle: Text(t.status),
                  onTap: () => _openPanel(ticketId: t.id),
                );
              },
            ),

          // 2) Overlay pour fermer au clic en dehors
          if (_showPanel)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closePanel,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.black26),
              ),
            ),

          // 3) Le panneau glissant
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
                child: _panelTicketId == null
                    ? SupportFormScreen(onSaved: _closePanel)
                    : SupportDetailScreen(ticketId: _panelTicketId!),
              ),
            ),
          ),
        ],
      ),

      // On cache le FAB lorsque le panneau est ouvert
      floatingActionButton: !_showPanel
          ? FloatingActionButton(
        tooltip: 'Nouveau ticket',
        child: const Icon(Icons.add),
        onPressed: () => _openPanel(ticketId: null),
      )
          : null,
    );
  }
}