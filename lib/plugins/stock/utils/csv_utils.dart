import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import '../models/product.dart';

class CsvUtils {
  /// Génère un contenu CSV à partir d'une liste de produits
  static String generateProductCsv(List<Product> products) {
    final List<List<dynamic>> rows = [
      [
        'id',
        'sku',
        'barcode',
        'name',
        'description',
        'categoryId',
        'supplierId',
        'unitPrice',
        'costPrice',
        'unitOfMeasure',
        'imageUrl',
        'quantityInStock',
        'reorderThreshold',
        'reorderQuantity',
        'minimumStock',
        'maximumStock',
        'dateCreated',
        'dateUpdated',
        'expiryDate',
      ]
    ];

    for (final p in products) {
      rows.add([
        p.id,
        p.sku,
        p.barcode,
        p.name,
        p.description,
        p.categoryId,
        p.supplierId,
        p.unitPrice,
        p.costPrice,
        p.unitOfMeasure,
        p.imageUrl,
        p.quantityInStock,
        p.reorderThreshold,
        p.reorderQuantity,
        p.minimumStock,
        p.maximumStock,
        p.dateCreated.toIso8601String(),
        p.dateUpdated.toIso8601String(),
        p.expiryDate?.toIso8601String() ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Permet de choisir un fichier CSV et retourne les produits parsés
  static Future<List<Product>> pickAndParseProductCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      final csvContent = utf8.decode(bytes);
      return parseProductCsv(csvContent);
    } else {
      return [];
    }
  }

  /// Transforme un contenu CSV en liste de produits
  static List<Product> parseProductCsv(String csvContent) {
    final rows = const CsvToListConverter().convert(csvContent, eol: '\n');
    final header = rows.first;
    final List<Product> products = [];

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final Map<String, dynamic> data = {
        for (var j = 0; j < header.length; j++) header[j]: row[j],
      };

      products.add(Product(
        id: data['id'].toString(),
        sku: data['sku'].toString(),
        barcode: data['barcode'].toString(),
        name: data['name'].toString(),
        description: data['description'].toString(),
        categoryId: data['categoryId'].toString(),
        supplierId: data['supplierId'].toString(),
        unitPrice: double.tryParse(data['unitPrice'].toString()) ?? 0.0,
        costPrice: double.tryParse(data['costPrice'].toString()) ?? 0.0,
        unitOfMeasure: data['unitOfMeasure'].toString(),
        imageUrl: data['imageUrl'].toString(),
        quantityInStock: int.tryParse(data['quantityInStock'].toString()) ?? 0,
        reorderThreshold: int.tryParse(data['reorderThreshold'].toString()) ?? 0,
        reorderQuantity: int.tryParse(data['reorderQuantity'].toString()) ?? 0,
        minimumStock: int.tryParse(data['minimumStock'].toString()) ?? 0,
        maximumStock: int.tryParse(data['maximumStock'].toString()) ?? 0,
        dateCreated: DateTime.tryParse(data['dateCreated'].toString()) ?? DateTime.now(),
        dateUpdated: DateTime.tryParse(data['dateUpdated'].toString()) ?? DateTime.now(),
        expiryDate: data['expiryDate'].toString().isNotEmpty
            ? DateTime.tryParse(data['expiryDate'].toString())
            : null,
      ));
    }

    return products;
  }
}
