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
  final VoidCallback? onClose;
  const QuoteDetailScreen({Key? key, required this.quoteId, this.onClose})
      : super(key: key);

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
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
        ),
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
              if (widget.onClose != null) {
                widget.onClose!();
              } else {
                Navigator.of(context).pop();
              }
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
              if (_quote!.notes != null && _quote!.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Notes : ${_quote!.notes!}',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
