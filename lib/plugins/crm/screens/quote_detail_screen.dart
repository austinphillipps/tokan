// lib/plugins/crm/screens/quote_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:tokan/main.dart'; // pour AppColors
import 'package:tokan/plugins/crm/providers/quote_provider.dart';
import 'package:tokan/plugins/crm/models/quote.dart';
import 'package:tokan/plugins/crm/screens/quote_form_screen.dart';
import 'package:tokan/plugins/crm/services/quote_pdf_service.dart';

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
            icon: const Icon(Icons.print),
            onPressed: () async {
              if (_quote != null) {
                await QuotePdfService().printQuote(_quote!);
              }
            },
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
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.black),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _quote == null
                ? const Center(child: Text('Devis introuvable'))
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Référence : ${_quote!.reference}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Total : ${NumberFormat.currency(symbol: '€').format(_quote!.total)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_quote!.discount != null) ...[
                  const SizedBox(height: 8),
                  Text('Remise : ${_quote!.discount!.toStringAsFixed(2)}%',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
                const SizedBox(height: 8),
                Text('Statut : ${_quote!.status}',
                    style: Theme.of(context).textTheme.titleMedium),
                if (_quote!.customer != null && _quote!.customer!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Client : ${_quote!.customer!}',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
                const SizedBox(height: 8),
                Text(
                  'Créé le : ${DateFormat.yMd().format(_quote!.createdAt)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (_quote!.dueDate != null) ...[
                  const SizedBox(height: 8),
                  Text('Échéance : ${DateFormat.yMd().format(_quote!.dueDate!)}',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
                if (_quote!.description != null && _quote!.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Description : ${_quote!.description!}',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
                if (_quote!.items.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Détails', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ..._quote!.items.map((e) => Text(
                      '${e.designation} - ${e.quantity} x ${e.unitPrice.toStringAsFixed(2)} €')),
                ],
                if (_quote!.notes != null && _quote!.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Notes : ${_quote!.notes!}',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 8),
                Text('TVA : ${_quote!.vatRate.toStringAsFixed(2)}%',
                    style: Theme.of(context).textTheme.bodyMedium),
                if (_quote!.iban != null && _quote!.iban!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('IBAN : ${_quote!.iban!}',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
                if (_quote!.bic != null && _quote!.bic!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('BIC : ${_quote!.bic!}',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
                if (_quote!.depositPercent != null) ...[
                  const SizedBox(height: 8),
                  Text('Acompte : ${_quote!.depositPercent!.toStringAsFixed(2)}%',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}