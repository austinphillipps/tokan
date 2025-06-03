// lib/plugins/stock/models/purchase_order.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseOrderLine {
  final String productId;
  final int quantity;
  final double unitPrice;

  PurchaseOrderLine({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  factory PurchaseOrderLine.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderLine(
      productId: map['productId'] as String? ?? '',
      quantity: map['quantity'] as int? ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

enum PurchaseOrderStatus { PENDING, RECEIVED, CANCELLED }

class PurchaseOrder {
  final String id;
  final String poNumber;
  final String supplierId;
  final DateTime dateOrdered;
  final DateTime? dateReceived;
  final PurchaseOrderStatus status;
  final List<PurchaseOrderLine> orderLines;

  PurchaseOrder({
    required this.id,
    required this.poNumber,
    required this.supplierId,
    required this.dateOrdered,
    this.dateReceived,
    required this.status,
    required this.orderLines,
  });

  Map<String, dynamic> toMap() {
    return {
      'poNumber': poNumber,
      'supplierId': supplierId,
      'dateOrdered': Timestamp.fromDate(dateOrdered),
      'dateReceived':
      dateReceived != null ? Timestamp.fromDate(dateReceived!) : null,
      'status': status.name,
      'orderLines': orderLines.map((l) => l.toMap()).toList(),
    };
  }

  factory PurchaseOrder.fromMap(String id, Map<String, dynamic> map) {
    final rawLines = map['orderLines'] as List<dynamic>? ?? [];
    return PurchaseOrder(
      id: id,
      poNumber: map['poNumber'] as String? ?? '',
      supplierId: map['supplierId'] as String? ?? '',
      dateOrdered:
      (map['dateOrdered'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateReceived: (map['dateReceived'] as Timestamp?)?.toDate(),
      status: PurchaseOrderStatus.values.firstWhere(
            (e) => e.name == (map['status'] as String? ?? 'PENDING'),
        orElse: () => PurchaseOrderStatus.PENDING,
      ),
      orderLines: rawLines
          .map((e) => PurchaseOrderLine.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
