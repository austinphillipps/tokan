// Modèle représentant un contact dans le CRM
import 'package:cloud_firestore/cloud_firestore.dart';

class Contact {
  /// Identifiant Firestore
  String? id;

  /// Prénom du contact
  String firstName;

  /// Nom du contact
  String name;

  /// Adresse e-mail
  String email;

  /// Numéro de téléphone (optionnel)
  String? phone;

  /// Date de création dans la base
  DateTime createdAt;

  Contact({
    this.id,
    required this.firstName,
    required this.name,
    required this.email,
    this.phone,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Crée une instance de [Contact] à partir d'un document Firestore
  factory Contact.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Contact(
      id: doc.id,
      firstName: data['firstName'] as String? ?? '',
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convertit l'instance en Map pour Firestore
  /// Utilise [Timestamp] pour conserver la compatibilité Firestore
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'name': name,
      'email': email,
      'phone': phone,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}