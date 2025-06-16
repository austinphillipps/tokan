// lib/plugins/crm/screens/support_form_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tokan/main.dart'; // pour AppColors

import 'package:tokan/plugins/crm/models/support_ticket.dart' as model;
import 'package:tokan/plugins/crm/providers/support_ticket_provider.dart';

class SupportFormScreen extends StatefulWidget {
  /// Si ticketId est null, on crée un nouveau ticket, sinon on édite
  final String? ticketId;
  final VoidCallback? onSaved;
  const SupportFormScreen({Key? key, this.ticketId, this.onSaved}) : super(key: key);

  @override
  _SupportFormScreenState createState() => _SupportFormScreenState();
}

class _SupportFormScreenState extends State<SupportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _status = 'Ouvert';
  bool _loading = false;

  bool get _isEditing => widget.ticketId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      // Chargement du ticket existant
      setState(() => _loading = true);
      context
          .read<SupportTicketProvider>()
          .fetchById(widget.ticketId!)
          .then((t) {
        if (t != null) {
          _titleCtrl.text = t.title;
          _descCtrl.text = t.description;
          _status = t.status;
        }
      }).whenComplete(() => setState(() => _loading = false));
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<SupportTicketProvider>();

    final ticket = model.SupportTicket(
      id: widget.ticketId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      status: _status,
      createdAt: _isEditing ? null : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() => _loading = true);
    if (_isEditing) {
      await provider.update(ticket);
    } else {
      await provider.create(ticket);
    }
    setState(() => _loading = false);
    if (widget.onSaved != null) {
      widget.onSaved!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Effet « verre » sous l’AppBar
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: AppColors.glassHeader,
        elevation: 0,
        title: Text(
          _isEditing ? 'Modifier Ticket' : 'Nouveau Ticket',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SafeArea(
        child: Container(
          color: AppColors.glassBackground,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Form(
            key: _formKey,
            child: ListView(
              children: [
                // Titre
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Titre'),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),

                // Statut
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Statut'),
                  items: ['Ouvert', 'En cours', 'Résolu']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _status = v!),
                ),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton(
            onPressed: _loading ? null : _onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _loading
                ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(color: Colors.white),
            )
                : Text(_isEditing ? 'Mettre à jour' : 'Créer'),
          ),
        ),
      ),
    );
  }
}