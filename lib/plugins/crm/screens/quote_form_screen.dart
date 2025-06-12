// lib/plugins/crm/screens/quote_form_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:tokan/main.dart'; // pour AppColors
import 'package:tokan/plugins/crm/models/quote.dart';
import 'package:tokan/plugins/crm/providers/quote_provider.dart';

class QuoteFormScreen extends StatefulWidget {
  /// Si quoteId est null, on est en création, sinon en édition
  final String? quoteId;
  const QuoteFormScreen({Key? key, this.quoteId}) : super(key: key);

  @override
  State<QuoteFormScreen> createState() => _QuoteFormScreenState();
}

class _QuoteFormScreenState extends State<QuoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _reference;
  double? _total;
  String _status = 'Brouillon';
  String? _customer;
  String? _description;
  String? _dueDateStr;
  double? _discount;
  String? _notes;
  bool _loading = false;

  bool get _isEditing => widget.quoteId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      context.read<QuoteProvider>().fetchById(widget.quoteId!).then((q) {
        if (q != null) {
          setState(() {
            _reference = q.reference;
            _total = q.total;
            _status = q.status;
            _customer = q.customer;
            _description = q.description;
            _dueDateStr = q.dueDate == null
                ? null
                : DateFormat('yyyy-MM-dd').format(q.dueDate!);
            _discount = q.discount;
            _notes = q.notes;
          });
        }
      });
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _loading = true);

    final provider = context.read<QuoteProvider>();
    if (_isEditing) {
      await provider.update(
        Quote(
          id: widget.quoteId,
          reference: _reference!,
          total: _total!,
          status: _status,
          customer: _customer,
          description: _description,
          dueDate: _dueDateStr == null || _dueDateStr!.isEmpty
              ? null
              : DateTime.tryParse(_dueDateStr!),
          discount: _discount,
          notes: _notes,
        ),
      );
    } else {
      await provider.create(
        Quote(
          reference: _reference!,
          total: _total!,
          status: _status,
          customer: _customer,
          description: _description,
          dueDate: _dueDateStr == null || _dueDateStr!.isEmpty
              ? null
              : DateTime.tryParse(_dueDateStr!),
          discount: _discount,
          notes: _notes,
        ),
      );
    }

    setState(() => _loading = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Modifier Devis' : 'Nouveau Devis',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.glassHeader,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Container(
          color: AppColors.glassBackground,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  initialValue: _reference,
                  decoration: const InputDecoration(labelText: 'Référence'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Obligatoire' : null,
                  onSaved: (v) => _reference = v,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _total?.toStringAsFixed(2),
                  decoration: const InputDecoration(labelText: 'Total (€)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => (v == null || double.tryParse(v) == null)
                      ? 'Montant invalide'
                      : null,
                  onSaved: (v) => _total = double.parse(v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _discount?.toStringAsFixed(2),
                  decoration: const InputDecoration(labelText: 'Remise (%)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSaved: (v) => _discount =
                      v == null || v.isEmpty ? null : double.tryParse(v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Statut'),
                  items: ['Brouillon', 'Envoyé', 'Accepté', 'Refusé']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _status = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _customer,
                  decoration: const InputDecoration(labelText: 'Client'),
                  onSaved: (v) => _customer = v,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _dueDateStr,
                  decoration: const InputDecoration(labelText: 'Échéance (YYYY-MM-DD)'),
                  keyboardType: TextInputType.datetime,
                  onSaved: (v) => _dueDateStr = v,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                  onSaved: (v) => _description = v,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                  onSaved: (v) => _notes = v,
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
