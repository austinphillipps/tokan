// lib/plugins/crm/screens/support_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tokan/main.dart'; // pour AppColors
import '../providers/support_ticket_provider.dart';
import '../models/support_ticket.dart' as model;
import 'support_form_screen.dart';

class SupportDetailScreen extends StatefulWidget {
  final String ticketId;
  const SupportDetailScreen({Key? key, required this.ticketId}) : super(key: key);

  @override
  _SupportDetailScreenState createState() => _SupportDetailScreenState();
}

class _SupportDetailScreenState extends State<SupportDetailScreen> {
  model.SupportTicket? _ticket;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    context
        .read<SupportTicketProvider>()
        .fetchById(widget.ticketId)
        .then((t) {
      setState(() {
        _ticket = t;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Affichage loading
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.glassBackground,
        appBar: AppBar(
          backgroundColor: AppColors.glassHeader,
          elevation: 0,
          title: const Text('Ticket'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Ticket introuvable
    if (_ticket == null) {
      return Scaffold(
        backgroundColor: AppColors.glassBackground,
        appBar: AppBar(
          backgroundColor: AppColors.glassHeader,
          elevation: 0,
          title: const Text('Ticket'),
        ),
        body: const Center(child: Text('Ticket introuvable')),
      );
    }

    // Affichage détail
    return Scaffold(
      backgroundColor: AppColors.glassBackground,
      appBar: AppBar(
        backgroundColor: AppColors.glassHeader,
        elevation: 0,
        title: Text(_ticket!.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SupportFormScreen(ticketId: widget.ticketId),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () async {
              await context.read<SupportTicketProvider>().delete(widget.ticketId);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Description :', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_ticket!.description),
          const SizedBox(height: 16),
          Text('Statut : ${_ticket!.status}', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text('Créé le : ${_ticket!.createdAt.toLocal()}', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text('Mis à jour : ${_ticket!.updatedAt.toLocal()}', style: Theme.of(context).textTheme.bodyMedium),
        ]),
      ),
    );
  }
}