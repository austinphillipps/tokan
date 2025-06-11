// lib/plugins/crm/models/opportunity.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Opportunity {
  String? id;
  String name;
  double amount;
  String stage;
  DateTime createdAt;

  Opportunity({
    this.id,
    required this.name,
    required this.amount,
    this.stage = 'Prospect',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Opportunity.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Opportunity(
      id: doc.id,
      name: data['name'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      stage: data['stage'] ?? 'Prospect',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'amount': amount,
    'stage': stage,
    'createdAt': createdAt,
  };
}
