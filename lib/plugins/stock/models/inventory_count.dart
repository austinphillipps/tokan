// lib/plugins/stock/models/inventory_count.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryLine {
  final String productId;
  final int countedQuantity;

  InventoryLine({
    required this.productId,
    required this.countedQuantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'countedQuantity': countedQuantity,
    };
  }

  factory InventoryLine.fromMap(Map<String, dynamic> map) {
    return InventoryLine(
      productId: map['productId'] as String? ?? '',
      countedQuantity: map['countedQuantity'] as int? ?? 0,
    );
  }
}

class InventoryCount {
  final String id;
  final DateTime date;
  final String locationId;
  final String performedBy; // ID de l’utilisateur
  final List<InventoryLine> lines;

  InventoryCount({
    required this.id,
    required this.date,
    required this.locationId,
    required this.performedBy,
    required this.lines,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'locationId': locationId,
      'performedBy': performedBy,
      'lines': lines.map((l) => l.toMap()).toList(),
    };
  }

  factory InventoryCount.fromMap(String id, Map<String, dynamic> map) {
    final rawLines = map['lines'] as List<dynamic>? ?? [];
    return InventoryCount(
      id: id,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      locationId: map['locationId'] as String? ?? '',
      performedBy: map['performedBy'] as String? ?? '',
      lines: rawLines
          .map((e) => InventoryLine.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
