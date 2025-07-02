// lib/plugins/crm/screens/quote_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tokan/main.dart'; // pour AppColors
import '../providers/quote_provider.dart';
import '../models/quote.dart';
import 'quote_form_screen.dart';

class QuoteListScreen extends StatefulWidget {
  const QuoteListScreen({Key? key}) : super(key: key);

  @override
  State<QuoteListScreen> createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
  bool _showPanel = false;
  String? _panelQuoteId;

  /// Ouvre le panneau (form si [quoteId]==null, sinon détail)
  void _openPanel({String? quoteId}) {
    setState(() {
      _panelQuoteId = quoteId;
      _showPanel = true;
    });
  }

  /// Ferme le panneau
  void _closePanel() {
    setState(() {
      _showPanel = false;
      _panelQuoteId = null;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuoteProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<QuoteProvider>();

    return Scaffold(
      backgroundColor: AppColors.darkGreyBackground,
      appBar: AppBar(
        title: const Text('Devis'),
        centerTitle: false,               // titre aligné à gauche
        automaticallyImplyLeading: false, // désactive le back-button
        leading: const SizedBox.shrink(), // retire complètement la zone de retour
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: prov.isLoading
                ? const Center(child: CircularProgressIndicator())
                : prov.quotes.isEmpty
                ? Center(
              child: ElevatedButton.icon(
                onPressed: () => _openPanel(quoteId: null),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter votre premier devis'),
              ),
            )
                : ListView.builder(
              itemCount: prov.quotes.length,
              itemBuilder: (_, i) {
                final q = prov.quotes[i];
                return ListTile(
                  title: Text(q.reference),
                  subtitle:
                  Text('${q.total.toStringAsFixed(2)} €'),
                  trailing: Text(q.status),
                  onTap: () => _openPanel(quoteId: q.id),
                );
              },
            ),
          ),

          // 2) Panneau plein écran
          if (_showPanel)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closePanel,
                behavior: HitTestBehavior.translucent,
                child: Container(
                  color: AppColors.darkGreyBackground,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {},
                      child: Material(
                        elevation: 16,
                        color: Colors.white,
                        child: SizedBox(
                          width: 794,
                          child: DefaultTextStyle.merge(
                            style: const TextStyle(color: Colors.black),
                            child: SafeArea(
                              child: _panelQuoteId == null
                                  ? QuoteFormScreen(onSaved: _closePanel)
                                  : QuoteFormScreen(
                                quoteId: _panelQuoteId!,
                                onSaved: _closePanel,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: !_showPanel
          ? FloatingActionButton(
        tooltip: 'Nouveau devis',
        child: const Icon(Icons.add),
        onPressed: () => _openPanel(quoteId: null),
      )
          : null,
    );
  }
}