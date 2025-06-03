// lib/plugins/stock/models/stock_movement.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum StockMovementType { IN, OUT, ADJUSTMENT, TRANSFER }

class StockMovement {
  final String id;
  final String productId;
  final StockMovementType type;
  final int quantity;
  final DateTime date;
  final String reference;
  final String? locationFrom;
  final String? locationTo;
  final String userId;
  final String reason;
  final String notes;

  StockMovement({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.date,
    required this.reference,
    this.locationFrom,
    this.locationTo,
    required this.userId,
    required this.reason,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'type': type.name,
      'quantity': quantity,
      'date': Timestamp.fromDate(date),
      'reference': reference,
      'locationFrom': locationFrom,
      'locationTo': locationTo,
      'userId': userId,
      'reason': reason,
      'notes': notes,
    };
  }

  factory StockMovement.fromMap(String id, Map<String, dynamic> map) {
    return StockMovement(
      id: id,
      productId: map['productId'] as String? ?? '',
      type: StockMovementType.values.firstWhere(
            (e) => e.name == (map['type'] as String? ?? 'IN'),
        orElse: () => StockMovementType.IN,
      ),
      quantity: map['quantity'] as int? ?? 0,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reference: map['reference'] as String? ?? '',
      locationFrom: map['locationFrom'] as String?,
      locationTo: map['locationTo'] as String?,
      userId: map['userId'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
    );
  }
}
