// lib/plugins/crm/models/quote.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Quote {
  String? id;
  String reference;
  double total;
  String status;
  DateTime createdAt;

  Quote({
    this.id,
    required this.reference,
    required this.total,
    required this.status,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Quote.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Quote(
      id: doc.id,
      reference: data['reference'] as String? ?? '',
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'Brouillon',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'reference': reference,
    'total': total,
    'status': status,
    'createdAt': createdAt,
  };
}
