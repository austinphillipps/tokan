// lib/plugins/crm/screens/quote_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:tokan/main.dart'; // pour AppColors
import 'package:tokan/plugins/crm/providers/quote_provider.dart';
import 'package:tokan/plugins/crm/models/quote.dart';
import 'package:tokan/plugins/crm/screens/quote_form_screen.dart';

class QuoteDetailScreen extends StatefulWidget {
  final String quoteId;
  const QuoteDetailScreen({Key? key, required this.quoteId}) : super(key: key);

  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen> {
  Quote? _quote;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    context.read<QuoteProvider>().fetchById(widget.quoteId).then((q) {
      setState(() {
        _quote = q;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // On laisse les couches derrière
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: AppColors.glassHeader,
        elevation: 0,
        title: Text(
          _loading
              ? 'Devis'
              : _quote != null
              ? 'Devis ${_quote!.reference}'
              : 'Devis introuvable',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: (_loading || _quote == null)
            ? null
            : [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QuoteFormScreen(quoteId: widget.quoteId),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await context.read<QuoteProvider>().delete(widget.quoteId);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),

      body: SafeArea(
        child: Container(
          // couche « glass »
          color: AppColors.glassBackground,
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _quote == null
                  ? const Center(child: Text('Devis introuvable'))
                  : _buildContent(context),
        ),
      ),
      );
  }

  Widget _buildContent(BuildContext context) {
    final subTotal = _quote!.items.fold<double>(
        0, (prev, item) => prev + item.total);
    final totalHt = subTotal - (_quote!.discount ?? 0);
    final vatAmount = totalHt * _quote!.vatRate / 100;
    final totalTtc = totalHt + vatAmount;

    return ListView(
      children: [
        Text('Référence : ${_quote!.reference}',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_quote!.customer != null && _quote!.customer!.isNotEmpty) ...[
          Text('Client : ${_quote!.customer!}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
        ],
        Text('Statut : ${_quote!.status}',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('Créé le : ${DateFormat.yMd().format(_quote!.createdAt)}',
            style: Theme.of(context).textTheme.bodyMedium),
        if (_quote!.dueDate != null) ...[
          const SizedBox(height: 8),
          Text('Échéance : ${DateFormat.yMd().format(_quote!.dueDate!)}',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
        if (_quote!.description != null && _quote!.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_quote!.description!,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
        if (_quote!.items.isNotEmpty) ...[
          const SizedBox(height: 16),
          DataTable(
            columns: const [
              DataColumn(label: Text('Désignation')),
              DataColumn(label: Text('Qté')),
              DataColumn(label: Text('P.U')),
              DataColumn(label: Text('Total')),
            ],
            rows: _quote!.items
                .map((e) => DataRow(cells: [
                      DataCell(Text(e.designation)),
                      DataCell(Text(e.quantity.toStringAsFixed(2))),
                      DataCell(Text(e.unitPrice.toStringAsFixed(2))),
                      DataCell(Text(e.total.toStringAsFixed(2))),
                    ]))
                .toList(),
          ),
        ],
        const SizedBox(height: 16),
        Text('Sous-total HT : ${subTotal.toStringAsFixed(2)} €'),
        if (_quote!.discount != null) ...[
          Text('Remise : -${_quote!.discount!.toStringAsFixed(2)} €'),
        ],
        Text('Total HT : ${totalHt.toStringAsFixed(2)} €'),
        Text('TVA ${_quote!.vatRate.toStringAsFixed(2)}% : ${vatAmount.toStringAsFixed(2)} €'),
        Text('Total TTC : ${totalTtc.toStringAsFixed(2)} €'),
        if (_quote!.depositPercent != null) ...[
          Text('Acompte ${_quote!.depositPercent!.toStringAsFixed(2)}% : '
              '${(totalTtc * _quote!.depositPercent! / 100).toStringAsFixed(2)} €'),
        ],
        if (_quote!.notes != null && _quote!.notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Notes : ${_quote!.notes!}'),
        ],
        if (_quote!.iban != null && _quote!.iban!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('IBAN : ${_quote!.iban!}'),
        ],
        if (_quote!.bic != null && _quote!.bic!.isNotEmpty) ...[
          Text('BIC : ${_quote!.bic!}'),
        ],
      ],
    );
  }
}
