// lib/plugins/crm/providers/quote_provider.dart

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tokan/plugins/crm/models/quote.dart';

class QuoteProvider extends ChangeNotifier {
  final User _user = FirebaseAuth.instance.currentUser!;
  late final CollectionReference _ref;

  final List<Quote> _quotes = [];
  List<Quote> get quotes => List.unmodifiable(_quotes);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  QuoteProvider() {
    _ref = FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('quotes');
  }

  /// Récupère tous les devis, ordonnés par date de création (descendant)
  Future<void> fetchAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await _ref.orderBy('createdAt', descending: true).get();
      _quotes
        ..clear()
        ..addAll(snap.docs.map((d) => Quote.fromDoc(d)));
    } catch (e) {
      debugPrint('Error fetching quotes: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Récupère un devis par son ID
  Future<Quote?> fetchById(String id) async {
    try {
      final doc = await _ref.doc(id).get();
      if (doc.exists) {
        return Quote.fromDoc(doc);
      }
    } catch (e) {
      debugPrint('Error fetching quote $id: $e');
    }
    return null;
  }

  /// Crée un nouveau devis et l’ajoute à la liste locale
  Future<void> create(Quote q) async {
    try {
      final doc = await _ref.add(q.toMap());
      q.id = doc.id;
      _quotes.insert(0, q);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating quote: $e');
    }
  }

  /// Met à jour un devis existant
  Future<void> update(Quote q) async {
    if (q.id == null) return;
    try {
      await _ref.doc(q.id).update(q.toMap());
      final index = _quotes.indexWhere((e) => e.id == q.id);
      if (index != -1) {
        _quotes[index] = q;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating quote: $e');
    }
  }

  /// Supprime un devis
  Future<void> delete(String id) async {
    try {
      await _ref.doc(id).delete();
      _quotes.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting quote: $e');
    }
  }
}
