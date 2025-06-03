// lib/plugins/stock/models/supplier.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Supplier {
  final String id;
  String name;
  String contactDetails; // ex. "email:xxx, tel:xxx, adresse:xxx"
  int leadTime; // en jours
  String paymentTerms;
  String notes;

  Supplier({
    required this.id,
    required this.name,
    required this.contactDetails,
    required this.leadTime,
    required this.paymentTerms,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'contactDetails': contactDetails,
      'leadTime': leadTime,
      'paymentTerms': paymentTerms,
      'notes': notes,
    };
  }

  factory Supplier.fromMap(String id, Map<String, dynamic> map) {
    return Supplier(
      id: id,
      name: map['name'] as String? ?? '',
      contactDetails: map['contactDetails'] as String? ?? '',
      leadTime: map['leadTime'] as int? ?? 0,
      paymentTerms: map['paymentTerms'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
    );
  }
}
