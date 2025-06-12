// lib/plugins/crm/screens/quote_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tokan/main.dart'; // pour AppColors
import '../providers/quote_provider.dart';
import '../models/quote.dart';
import 'quote_detail_screen.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devis'),
        centerTitle: false,               // titre aligné à gauche
        automaticallyImplyLeading: false, // désactive le back-button
        leading: const SizedBox.shrink(), // retire complètement la zone de retour
      ),
      body: Stack(
        children: [
          // 1) La liste des devis
          if (prov.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (prov.quotes.isEmpty)
            const Center(child: Text('Aucun devis pour le moment.'))
          else
            ListView.builder(
              itemCount: prov.quotes.length,
              itemBuilder: (_, i) {
                final q = prov.quotes[i];
                return Card(
                  margin:
                  const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    title: Text(q.reference),
                    subtitle: Text('${q.total.toStringAsFixed(2)} €'),
                    trailing: Text(q.status),
                    onTap: () => _openPanel(quoteId: q.id),
                  ),
                );
              },
            ),

          // 2) Overlay pour fermer au clic en dehors
          if (_showPanel)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closePanel,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.black26),
              ),
            ),

          // 3) Panneau latéral
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            top: 0,
            bottom: 0,
            right: _showPanel ? 0 : -screenWidth * 0.75,
            width: screenWidth * 0.25,
            child: Material(
              elevation: 16,
              color: AppColors.glassBackground,
              child: SafeArea(
                child: _panelQuoteId == null
                    ? QuoteFormScreen(onSaved: _closePanel)
                    : QuoteDetailScreen(quoteId: _panelQuoteId!),
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
