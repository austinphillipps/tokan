import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/quote.dart';

class QuotePdfService {
  Future<pw.Document> buildPdf(Quote quote) async {
    final doc = pw.Document();
    final Uint8List logoData =
        (await rootBundle.load('assets/images/tokan_logotype_black.png'))
            .buffer
            .asUint8List();
    final logo = pw.MemoryImage(logoData);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Image(logo, height: 60),
                    pw.Text(
                      'Devis ${quote.reference}',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                if (quote.customer != null && quote.customer!.isNotEmpty)
                  pw.Text('Client : ${quote.customer!}'),
                pw.Text('Statut : ${quote.status}'),
                pw.Text('Créé le : ${DateFormat.yMd().format(quote.createdAt)}'),
                if (quote.dueDate != null)
                  pw.Text('Échéance : ${DateFormat.yMd().format(quote.dueDate!)}'),
                pw.SizedBox(height: 16),
                pw.Table.fromTextArray(
                  headers: ['Description', 'Montant'],
                  data: [
                    [
                      quote.description ?? 'Voir détails',
                      '${quote.total.toStringAsFixed(2)} €'
                    ],
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Total : ${quote.total.toStringAsFixed(2)} €',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (quote.discount != null)
                  pw.Text('Remise : ${quote.discount!.toStringAsFixed(2)}%'),
                if (quote.notes != null && quote.notes!.isNotEmpty)
                  pw.Text('Notes : ${quote.notes!}'),
                pw.Spacer(),
                pw.Container(
                  height: 80,
                  width: double.infinity,
                  alignment: pw.Alignment.centerLeft,
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('RIB : à définir'),
                ),
              ],
            ),
          );
        },
      ),
    );
    return doc;
  }

  Future<void> printQuote(Quote quote) async {
    final doc = await buildPdf(quote);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }
}
