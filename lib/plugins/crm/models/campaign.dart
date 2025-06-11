import 'package:cloud_firestore/cloud_firestore.dart';

class Campaign {
  String? id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // ex. “Active”, “Draft”, “Completed”

  Campaign({
    this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.status = 'Draft',
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'status': status,
  };

  factory Campaign.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Campaign(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: data['status'] as String? ?? 'Draft',
    );
  }
}
