// Modèle représentant un contact dans le CRM
import 'package:cloud_firestore/cloud_firestore.dart';

class Contact {
  /// Identifiant Firestore
  String? id;
  /// Nom de famille du contact
  String name;
  /// Prénom du contact
  String firstName;
  /// Adresse e-mail
  String email;
  /// Indicatif téléphonique (ex: +33)
  String phonePrefix;
  /// Numéro de téléphone (optionnel)
  String? phone;
  /// Date de création dans la base
  DateTime createdAt;

  Contact({
    this.id,
    required this.name,
    required this.firstName,
    required this.email,
    this.phonePrefix = '+33',
    this.phone,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Crée une instance de [Contact] à partir d'un document Firestore
  factory Contact.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Contact(
      id: doc.id,
      name: data['name'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phonePrefix: data['phonePrefix'] as String? ?? '+33',
      phone: data['phone'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convertit l'instance en Map pour Firestore
  /// Utilise [Timestamp] pour conserver la compatibilité Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'firstName': firstName,
      'email': email,
      'phonePrefix': phonePrefix,
      'phone': phone,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
