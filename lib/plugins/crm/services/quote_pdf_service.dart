import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../models/quote.dart';

class QuotePdfService {
  Future<pw.Document> buildPdf(Quote quote) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final dateFormat = DateFormat('dd/MM/yyyy');
          final headers = ['Désignation', 'Qté', 'P.U', 'Total'];
          final data = quote.items.map((e) => [
            e.designation,
            e.quantity.toStringAsFixed(2),
            e.unitPrice.toStringAsFixed(2),
            e.total.toStringAsFixed(2),
          ]).toList();

          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('DEVIS',
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Réf. ${quote.reference}',
                        style: const pw.TextStyle(fontSize: 16)),
                  ],
                ),
                pw.SizedBox(height: 16),
                if (quote.customer != null && quote.customer!.isNotEmpty)
                  pw.Text('Client : ${quote.customer!}'),
                pw.Text('Statut : ${quote.status}'),
                pw.Text('Date : ${dateFormat.format(quote.createdAt)}'),
                if (quote.dueDate != null)
                  pw.Text('Échéance : ${dateFormat.format(quote.dueDate!)}'),
                if (quote.description != null && quote.description!.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  pw.Text(quote.description!),
                ],
                if (data.isNotEmpty) ...[
                  pw.SizedBox(height: 24),
                  pw.Table.fromTextArray(
                    headers: headers,
                    data: data,
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    cellAlignment: pw.Alignment.centerLeft,
                    columnWidths: {
                      0: const pw.FlexColumnWidth(4),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(2),
                      3: const pw.FlexColumnWidth(2),
                    },
                  ),
                ],
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        if (quote.discount != null)
                          pw.Text('Remise : ${quote.discount!.toStringAsFixed(2)} %'),
                        pw.Text('TVA : ${quote.vatRate.toStringAsFixed(2)} %'),
                        pw.Text('Total : ${quote.total.toStringAsFixed(2)} €',
                            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                if (quote.notes != null && quote.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  pw.Text('Notes :'),
                  pw.Text(quote.notes!),
                ],
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