// lib/plugins/stock/models/product.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String sku;
  final String barcode;
  String name;
  String description;
  String categoryId;
  String supplierId;
  double unitPrice;
  double costPrice;
  String unitOfMeasure;
  String imageUrl;
  int quantityInStock;
  int reorderThreshold;
  int reorderQuantity;
  int minimumStock;
  int maximumStock;
  DateTime dateCreated;
  DateTime dateUpdated;
  DateTime? expiryDate;

  Product({
    required this.id,
    required this.sku,
    required this.barcode,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.supplierId,
    required this.unitPrice,
    required this.costPrice,
    required this.unitOfMeasure,
    required this.imageUrl,
    required this.quantityInStock,
    required this.reorderThreshold,
    required this.reorderQuantity,
    required this.minimumStock,
    required this.maximumStock,
    required this.dateCreated,
    required this.dateUpdated,
    this.expiryDate,
  });

  /// Convertit l’objet en Map pour stocker dans Firestore/SQLite.
  Map<String, dynamic> toMap() {
    return {
      'sku': sku,
      'barcode': barcode,
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'supplierId': supplierId,
      'unitPrice': unitPrice,
      'costPrice': costPrice,
      'unitOfMeasure': unitOfMeasure,
      'imageUrl': imageUrl,
      'quantityInStock': quantityInStock,
      'reorderThreshold': reorderThreshold,
      'reorderQuantity': reorderQuantity,
      'minimumStock': minimumStock,
      'maximumStock': maximumStock,
      'dateCreated': Timestamp.fromDate(dateCreated),
      'dateUpdated': Timestamp.fromDate(dateUpdated),
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
    };
  }

  /// Reconstruit un objet Product depuis un DocumentSnapshot Firestore.
  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      sku: map['sku'] as String? ?? '',
      barcode: map['barcode'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      supplierId: map['supplierId'] as String? ?? '',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0.0,
      unitOfMeasure: map['unitOfMeasure'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      quantityInStock: map['quantityInStock'] as int? ?? 0,
      reorderThreshold: map['reorderThreshold'] as int? ?? 0,
      reorderQuantity: map['reorderQuantity'] as int? ?? 0,
      minimumStock: map['minimumStock'] as int? ?? 0,
      maximumStock: map['maximumStock'] as int? ?? 0,
      dateCreated:
      (map['dateCreated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateUpdated:
      (map['dateUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
    );
  }
}
