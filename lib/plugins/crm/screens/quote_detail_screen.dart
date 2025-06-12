// lib/plugins/crm/screens/quote_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _quote == null
                ? const Center(child: Text('Devis introuvable'))
                : PdfPreview(
                    useActions: false,
                    build: (format) async {
                      final doc = await QuotePdfService().buildPdf(_quote!);
                      return doc.save();
                    },
                  ),
      ),
    );
  }
}
