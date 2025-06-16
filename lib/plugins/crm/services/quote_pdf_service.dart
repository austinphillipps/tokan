import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/quote.dart';

class QuotePdfService {
  Future<pw.Document> buildPdf(Quote quote) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Devis ${quote.reference}',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                if (quote.customer != null && quote.customer!.isNotEmpty)
                  pw.Text('Client : ${quote.customer!}'),
                pw.Text('Statut : ${quote.status}'),
                pw.Text('Créé le : ${quote.createdAt.toLocal()}'),
                if (quote.dueDate != null)
                  pw.Text('Échéance : ${quote.dueDate!.toLocal()}'),
                if (quote.description != null && quote.description!.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  pw.Text(quote.description!),
                ],
                pw.Spacer(),
                pw.Text('Total : ${quote.total.toStringAsFixed(2)} €',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                if (quote.discount != null)
                  pw.Text('Remise : ${quote.discount!.toStringAsFixed(2)}%'),
                if (quote.notes != null && quote.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  pw.Text('Notes : ${quote.notes!}'),
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