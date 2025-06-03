// lib/plugins/stock/models/category.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  String name;
  String? parentId;
  String description;

  Category({
    required this.id,
    required this.name,
    this.parentId,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'parentId': parentId,
      'description': description,
    };
  }

  factory Category.fromMap(String id, Map<String, dynamic> map) {
    return Category(
      id: id,
      name: map['name'] as String? ?? '',
      parentId: map['parentId'] as String?,
      description: map['description'] as String? ?? '',
    );
  }
}
