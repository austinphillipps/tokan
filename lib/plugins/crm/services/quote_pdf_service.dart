import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

import '../models/quote.dart';

class QuotePdfService {
  Future<pw.Document> buildPdf(Quote quote) async {
    final doc = pw.Document();

    final logoData = await rootBundle.load('assets/images/tokan_logotype_black.png');
    final logo = pw.MemoryImage(logoData.buffer.asUint8List());

    final dateFmt = DateFormat.yMd();

    final items = quote.items
        .map((i) => [
              i.designation,
              i.quantity.toStringAsFixed(2),
              i.unitPrice.toStringAsFixed(2),
              i.total.toStringAsFixed(2)
            ])
        .toList();

    final vatAmount = quote.total * quote.vatRate / 100;

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
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Image(logo, width: 80),
                    pw.SizedBox(width: 16),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Devis ${quote.reference}',
                            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        if (quote.customer != null && quote.customer!.isNotEmpty)
                          pw.Text('Client : ${quote.customer!}'),
                        pw.Text('Statut : ${quote.status}'),
                        pw.Text('Créé le : ${dateFmt.format(quote.createdAt)}'),
                        if (quote.dueDate != null)
                          pw.Text('Échéance : ${dateFmt.format(quote.dueDate!)}'),
                      ],
                    ),
                  ],
                ),
                if (quote.description != null && quote.description!.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  pw.Text(quote.description!),
                ],
                if (items.isNotEmpty) ...[
                  pw.SizedBox(height: 24),
                  pw.Table.fromTextArray(
                    headers: ['Désignation', 'Qté', 'P.U', 'Total'],
                    data: items,
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    cellAlignment: pw.Alignment.centerLeft,
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  ),
                ],
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Row(children: [
                          pw.Text('Total HT : '),
                          pw.Text('${quote.total.toStringAsFixed(2)} €'),
                        ]),
                        pw.Row(children: [
                          pw.Text('TVA (${quote.vatRate.toStringAsFixed(2)}%) : '),
                          pw.Text('${vatAmount.toStringAsFixed(2)} €'),
                        ]),
                        pw.Row(children: [
                          pw.Text('Total TTC : '),
                          pw.Text('${(quote.total + vatAmount).toStringAsFixed(2)} €'),
                        ]),
                      ],
                    )
                  ],
                ),
                if (quote.discount != null)
                  pw.Text('Remise : ${quote.discount!.toStringAsFixed(2)}%'),
                if (quote.depositPercent != null)
                  pw.Text('Acompte : ${quote.depositPercent!.toStringAsFixed(2)}%'),
                if (quote.notes != null && quote.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  pw.Text('Notes : ${quote.notes!}'),
                ],
                if (quote.iban != null && quote.iban!.isNotEmpty)
                  pw.Text('IBAN : ${quote.iban!}'),
                if (quote.bic != null && quote.bic!.isNotEmpty)
                  pw.Text('BIC : ${quote.bic!}'),
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