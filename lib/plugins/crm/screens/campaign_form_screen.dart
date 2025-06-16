// lib/plugins/crm/screens/campaign_form_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/campaign_provider.dart';
import '../models/campaign.dart';

class CampaignFormScreen extends StatefulWidget {
  final String? campaignId;
  final VoidCallback? onSaved;
  const CampaignFormScreen({Key? key, this.campaignId, this.onSaved})
      : super(key: key);

  @override
  State<CampaignFormScreen> createState() => _CampaignFormScreenState();
}

class _CampaignFormScreenState extends State<CampaignFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _status = 'Draft';

  bool _loading = false;
  Campaign? _editing;

  @override
  void initState() {
    super.initState();
    if (widget.campaignId != null) {
      _loading = true;
      context
          .read<CampaignProvider>()
          .fetchById(widget.campaignId!)
          .then((c) {
        if (c != null) {
          _editing = c;
          _nameCtrl.text = c.name;
          _descCtrl.text = c.description;
          _startDate = c.startDate;
          _endDate = c.endDate;
          _status = c.status;
        }
      }).whenComplete(() {
        setState(() => _loading = false);
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext ctx, bool isStart) async {
    final initial = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final date = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        if (isStart) _startDate = date;
        else _endDate = date;
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate() ||
        _startDate == null ||
        _endDate == null) {
      return;
    }
    final prov = context.read<CampaignProvider>();
    final camp = Campaign(
      id: _editing?.id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
      status: _status,
    );

    setState(() => _loading = true);
    if (_editing == null) {
      await prov.create(camp);
    } else {
      await prov.update(camp);
    }
    if (widget.onSaved != null) {
      widget.onSaved!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.campaignId != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Éditer Campagne' : 'Nouvelle Campagne')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) => v == null || v.isEmpty ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(_startDate == null
                    ? 'Date de début'
                    : 'Début : ${DateFormat.yMd().format(_startDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(context, true),
              ),
              ListTile(
                title: Text(_endDate == null
                    ? 'Date de fin'
                    : 'Fin : ${DateFormat.yMd().format(_endDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(context, false),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Statut'),
                items: ['Draft', 'Active', 'Completed']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: Text(isEdit ? 'Mettre à jour' : 'Créer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}