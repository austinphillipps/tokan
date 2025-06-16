// lib/plugins/crm/models/quote.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'quote_item.dart';

class Quote {
  String? id;
  String reference;
  double total;
  String status;
  DateTime createdAt;
  String? customer;
  String? description;
  DateTime? dueDate;
  double? discount;
  String? notes;
  List<QuoteItem> items;
  double vatRate;
  String? iban;
  String? bic;
  double? depositPercent;

  Quote({
    this.id,
    required this.reference,
    required this.total,
    required this.status,
    DateTime? createdAt,
    this.customer,
    this.description,
    this.dueDate,
    this.discount,
    this.notes,
    List<QuoteItem>? items,
    this.vatRate = 0,
    this.iban,
    this.bic,
    this.depositPercent,
  })  : items = items ?? [],
        createdAt = createdAt ?? DateTime.now();

  factory Quote.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Quote(
      id: doc.id,
      reference: data['reference'] as String? ?? '',
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'Brouillon',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      customer: data['customer'] as String?,
      description: data['description'] as String?,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      discount: (data['discount'] as num?)?.toDouble(),
      notes: data['notes'] as String?,
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => QuoteItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      vatRate: (data['vatRate'] as num?)?.toDouble() ?? 0.0,
      iban: data['iban'] as String?,
      bic: data['bic'] as String?,
      depositPercent: (data['depositPercent'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'reference': reference,
    'total': total,
    'status': status,
    'createdAt': createdAt,
    'customer': customer,
    'description': description,
    'dueDate': dueDate,
    'discount': discount,
    'notes': notes,
    'items': items.map((e) => e.toMap()).toList(),
    'vatRate': vatRate,
    'iban': iban,
    'bic': bic,
    'depositPercent': depositPercent,
  };
}