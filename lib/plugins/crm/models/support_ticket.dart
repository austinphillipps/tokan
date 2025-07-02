// lib/plugins/crm/models/support_ticket.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicket {
  String? id;
  final String title;
  final String description;
  final String status;     // « Ouvert », « En cours », « Résolu »
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportTicket({
    this.id,
    required this.title,
    required this.description,
    this.status = 'Ouvert',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory SupportTicket.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportTicket(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      status: data['status'] as String? ?? 'Ouvert',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
