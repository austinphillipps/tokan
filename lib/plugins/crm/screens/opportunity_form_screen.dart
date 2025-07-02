// lib/plugins/crm/screens/opportunity_form_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tokan/main.dart'; // pour AppColors
import 'package:tokan/plugins/crm/models/opportunity.dart';
import 'package:tokan/plugins/crm/providers/opportunity_provider.dart';

class OpportunityFormScreen extends StatefulWidget {
  /// Si opportunityId est null, on crée une nouvelle opportunité, sinon on édite
  final String? opportunityId;
  final VoidCallback? onSaved;
  const OpportunityFormScreen({Key? key, this.opportunityId, this.onSaved})
      : super(key: key);

  @override
  State<OpportunityFormScreen> createState() => _OpportunityFormScreenState();
}

class _OpportunityFormScreenState extends State<OpportunityFormScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _stage     = 'Prospect';
  bool _loading     = false;

  static const _stages = [
    'Prospect',
    'Qualification',
    'Négociation',
    'Gagné',
    'Perdu',
  ];

  bool get _isEditing => widget.opportunityId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    final opp = await context
        .read<OpportunityProvider>()
        .fetchById(widget.opportunityId!);
    if (opp != null) {
      _nameCtrl.text   = opp.name;
      _amountCtrl.text = opp.amount.toStringAsFixed(0);
      _stage           = opp.stage;
    }
    setState(() => _loading = false);
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final provider = context.read<OpportunityProvider>();
    final opp = Opportunity(
      id:     widget.opportunityId,
      name:   _nameCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.trim()),
      stage:  _stage,
      // createdAt and updatedAt are handled by the provider/model defaults
    );

    if (_isEditing) {
      await provider.update(opp);
    } else {
      await provider.create(opp);
    }
    setState(() => _loading = false);
    if (widget.onSaved != null) {
      widget.onSaved!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Modifier Opportunité' : 'Nouvelle Opportunité';

    return Scaffold(
      // Pour effet « verre » derrière l'AppBar
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: AppColors.glassHeader,
        elevation: 0,
        title: Text(
          title,
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
                // Intitulé
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Intitulé'),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Le nom est requis' : null,
                ),
                const SizedBox(height: 16),

                // Montant
                TextFormField(
                  controller: _amountCtrl,
                  decoration: const InputDecoration(labelText: 'Montant (€)'),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: false),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Montant requis';
                    return double.tryParse(v) == null
                        ? 'Nombre invalide'
                        : null;
                  },
                ),
                const SizedBox(height: 16),

                // Phase
                DropdownButtonFormField<String>(
                  value: _stage,
                  decoration: const InputDecoration(labelText: 'Phase'),
                  items: _stages
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _stage = v!),
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
                : Text(title),
          ),
        ),
      ),
    );
  }
}