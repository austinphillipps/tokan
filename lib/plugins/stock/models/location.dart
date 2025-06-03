// lib/plugins/stock/models/location.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Location {
  final String id;
  String name;
  String address;

  Location({
    required this.id,
    required this.name,
    required this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
    };
  }

  factory Location.fromMap(String id, Map<String, dynamic> map) {
    return Location(
      id: id,
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
    );
  }
}
