import 'package:flutter/material.dart';

class QuoteDetailScreen extends StatelessWidget {
  // Vous pouvez remplacer ces valeurs statiques par votre modèle Quote
  final String companyName = 'CHAMBRE DE MÉTIERS ET DE L\u2019ARTISANAT\nDE R\u00c9GION MARTINIQUE';
  final String companyAddress = 'Rue DU TEMPLE\n97200 FORT-DE-FRANCE France';
  final String quoteNumber = 'DEV000050';
  final String quoteDate = '28/05/2025';
  final String expirationDate = '27/06/2025';

  final List<QuoteLine> lines = [
    QuoteLine(
      description:
          'Conception & scenarisation (Reunion creative, redaction script 30 s, decoupage-plan)',
      qty: 1,
      unitPrice: '120,00 \u20ac',
      total: '120,00 \u20ac',
    ),
    QuoteLine(
      description: 'Pre-production / Recherche medias (HD/4K, licences)',
      qty: 1,
      unitPrice: '60,00 \u20ac',
      total: '60,00 \u20ac',
    ),
    QuoteLine(
      description:
          'Montage, habillage & VFX (Montage 4K, etalonnage, motion-graphics\u2026)',
      qty: 1,
      unitPrice: '290,00 \u20ac',
      total: '290,00 \u20ac',
    ),
    QuoteLine(
      description: 'Voix-off & musique libres de droit (Studio pro)',
      qty: 1,
      unitPrice: '90,00 \u20ac',
      total: '90,00 \u20ac',
    ),
    QuoteLine(
      description: 'Mastering & livrables (HD/4K, PAL 25 i/s, .mp4 & .mov)',
      qty: 1,
      unitPrice: '20,00 \u20ac',
      total: '20,00 \u20ac',
    ),
  ];

  final String subTotal = '580,00 \u20ac';
  final String vatAmount = '49,30 \u20ac';
  final String totalTTC = '629,30 \u20ac';

  const QuoteDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF006644);
    const accentColor = Color(0xFFEEEEEE);
    const headerTextStyle =
        TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white);
    const labelTextStyle =
        TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black);
    const valueTextStyle = TextStyle(fontSize: 14, color: Colors.black87);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Devis', style: TextStyle(color: primaryColor)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // —— EN-T\u00caTE ——
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  color: primaryColor,
                  child: const Center(
                    child: Text('Logo',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(companyName, style: labelTextStyle),
                      const SizedBox(height: 4),
                      Text(companyAddress, style: valueTextStyle),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _infoPair('N\u00b0 Devis :', quoteNumber),
                          const SizedBox(width: 16),
                          _infoPair('Date :', quoteDate),
                          const SizedBox(width: 16),
                          _infoPair('Expiration :', expirationDate),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // —— TABLEAU DES PRESTATIONS ——
            Container(
              color: accentColor,
              padding: const EdgeInsets.all(4),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(4),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2),
                },
                border: TableBorder.all(color: Colors.grey),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: primaryColor),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(6),
                        child: Text('D\u00e9signation', style: headerTextStyle),
                      ),
                      Padding(
                        padding: EdgeInsets.all(6),
                        child: Text('Qt\u00e9',
                            style: headerTextStyle, textAlign: TextAlign.center),
                      ),
                      Padding(
                        padding: EdgeInsets.all(6),
                        child: Text('P.U HT',
                            style: headerTextStyle, textAlign: TextAlign.right),
                      ),
                      Padding(
                        padding: EdgeInsets.all(6),
                        child: Text('Total HT',
                            style: headerTextStyle, textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                  for (var line in lines) _buildLineRow(line),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // —— R\u00c9CAPITULATIF ——
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _summaryRow('Sous-total HT :', subTotal),
                  _summaryRow('TVA 8,50 % :', vatAmount),
                  const Divider(color: Colors.grey),
                  _summaryRow('Total TTC :', totalTTC,
                      labelStyle: labelTextStyle.copyWith(fontSize: 16),
                      valueStyle: valueTextStyle.copyWith(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // —— PIED DE PAGE – RIB & MENTIONS ——
            Container(
              padding: const EdgeInsets.all(12),
              color: accentColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('RIB FRAMECASTLE STUDIO', style: labelTextStyle),
                  Text('IBAN : FR76 1659 6000 0114 1752 3250 54',
                      style: valueTextStyle),
                  Text('BIC/SWIFT : QNTOFRP1XXX', style: valueTextStyle),
                  SizedBox(height: 12),
                  Text(
                    'Signature du client precedee de la mention \xab Bon pour accord \xbb :',
                    style: valueTextStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'SAS FRAMECASTLE STUDIO – SIRET 910 945 252 00013 – Code NAF 7410Z\nTél. 06 20 37 81 04 – framecastlestudio@gmail.com',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPair(String label, String value) {
    return RichText(
      text: TextSpan(
        text: '$label ',
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
        children: [
          TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.normal)),
        ],
      ),
    );
  }

  TableRow _buildLineRow(QuoteLine line) {
    return TableRow(children: [
      Padding(
        padding: const EdgeInsets.all(6),
        child: Text(line.description, style: const TextStyle(fontSize: 13)),
      ),
      Padding(
        padding: const EdgeInsets.all(6),
        child: Text(line.qty.toString(), textAlign: TextAlign.center),
      ),
      Padding(
        padding: const EdgeInsets.all(6),
        child: Text(line.unitPrice, textAlign: TextAlign.right),
      ),
      Padding(
        padding: const EdgeInsets.all(6),
        child: Text(line.total, textAlign: TextAlign.right),
      ),
    ]);
  }

  Widget _summaryRow(String label, String value,
      {TextStyle? labelStyle, TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          text: label,
          style: labelStyle ??
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
          children: [
            TextSpan(text: ' $value', style: valueStyle ?? const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class QuoteLine {
  final String description;
  final int qty;
  final String unitPrice;
  final String total;

  QuoteLine({
    required this.description,
    required this.qty,
    required this.unitPrice,
    required this.total,
  });
}
