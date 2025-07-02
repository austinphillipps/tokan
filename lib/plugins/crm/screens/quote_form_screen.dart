// lib/plugins/crm/screens/quote_form_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:tokan/main.dart'; // pour AppColors
import 'package:tokan/plugins/crm/models/quote.dart';
import 'package:tokan/plugins/crm/models/quote_item.dart';
import 'package:tokan/plugins/crm/providers/quote_provider.dart';

class QuoteFormScreen extends StatefulWidget {
  /// Si quoteId est null, on est en création, sinon en édition
  final String? quoteId;
  final VoidCallback? onSaved;
  const QuoteFormScreen({Key? key, this.quoteId, this.onSaved}) : super(key: key);

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
  List<QuoteItem> _items = [QuoteItem(designation: '', quantity: 1, unitPrice: 0)];
  double _vatRate = 0;
  String? _iban;
  String? _bic;
  double? _depositPercent;
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
            _items = q.items.isEmpty
                ? [QuoteItem(designation: '', quantity: 1, unitPrice: 0)]
                : q.items.map((e) => QuoteItem(
              designation: e.designation,
              quantity: e.quantity,
              unitPrice: e.unitPrice,
            )).toList();
            _vatRate = q.vatRate;
            _iban = q.iban;
            _bic = q.bic;
            _depositPercent = q.depositPercent;
          });
        }
      });
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    _total = _items.fold<double>(0,
            (prev, e) => prev + e.quantity * e.unitPrice) - (_discount ?? 0);
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
          items: _items,
          vatRate: _vatRate,
          iban: _iban,
          bic: _bic,
          depositPercent: _depositPercent,
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
          items: _items,
          vatRate: _vatRate,
          iban: _iban,
          bic: _bic,
          depositPercent: _depositPercent,
        ),
      );
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
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.black),
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
                  Text(
                    'Lignes de devis',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ..._items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: TextFormField(
                              initialValue: item.designation,
                              decoration: const InputDecoration(labelText: 'Désignation'),
                              onChanged: (v) => item.designation = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: item.quantity.toString(),
                              decoration: const InputDecoration(labelText: 'Qté'),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (v) => item.quantity = double.tryParse(v) ?? 0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: item.unitPrice.toStringAsFixed(2),
                              decoration: const InputDecoration(labelText: 'P.U'),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (v) => item.unitPrice = double.tryParse(v) ?? 0,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => setState(() => _items.removeAt(index)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  TextButton.icon(
                    onPressed: () => setState(() => _items.add(
                        QuoteItem(designation: '', quantity: 1, unitPrice: 0))),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une ligne'),
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
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _vatRate.toStringAsFixed(2),
                    decoration: const InputDecoration(labelText: 'Taux TVA (%)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => _vatRate = double.tryParse(v) ?? 0,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _iban,
                    decoration: const InputDecoration(labelText: 'IBAN'),
                    onChanged: (v) => _iban = v,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _bic,
                    decoration: const InputDecoration(labelText: 'BIC/SWIFT'),
                    onChanged: (v) => _bic = v,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _depositPercent?.toStringAsFixed(2),
                    decoration: const InputDecoration(labelText: 'Acompte (%)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => _depositPercent = double.tryParse(v),
                  ),
                ],
              ),
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