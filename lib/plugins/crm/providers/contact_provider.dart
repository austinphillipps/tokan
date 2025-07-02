import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/contact.dart';

class ContactProvider extends ChangeNotifier {
  final _user = FirebaseAuth.instance.currentUser!;
  late final CollectionReference _contactsRef;

  ContactProvider() {
    _contactsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('contacts');
  }

  List<Contact> _contacts = [];
  List<Contact> get contacts => _contacts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await _contactsRef.orderBy('name').get();
      _contacts = snap.docs.map((d) => Contact.fromDoc(d)).toList();
    } catch (e) {
      debugPrint('Error fetching contacts: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Contact?> fetchById(String id) async {
    try {
      final doc = await _contactsRef.doc(id).get();
      if (doc.exists) {
        return Contact.fromDoc(doc);
      }
    } catch (e) {
      debugPrint('Error fetching contact $id: $e');
    }
    return null;
  }

  Future<void> create(Contact contact) async {
    try {
      final docRef = await _contactsRef.add(contact.toMap());
      contact.id = docRef.id;
      _contacts.add(contact);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating contact: $e');
    }
  }

  Future<void> update(Contact contact) async {
    if (contact.id == null) return;
    try {
      await _contactsRef.doc(contact.id).update(contact.toMap());
      final idx = _contacts.indexWhere((c) => c.id == contact.id);
      if (idx != -1) {
        _contacts[idx] = contact;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating contact: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _contactsRef.doc(id).delete();
      _contacts.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting contact: $e');
    }
  }
}
