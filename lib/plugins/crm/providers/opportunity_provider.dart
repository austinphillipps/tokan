import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Utilisez un import absolu pour être sûr du chemin
import 'package:tokan/plugins/crm/models/opportunity.dart';

class OpportunityProvider extends ChangeNotifier {
  final User _user = FirebaseAuth.instance.currentUser!;
  late final CollectionReference _oppRef;

  OpportunityProvider() {
    _oppRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('opportunities');
  }

  final List<Opportunity> _opportunities = [];
  List<Opportunity> get opportunities => List.unmodifiable(_opportunities);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await _oppRef
          .orderBy('createdAt', descending: true)
          .get();
      _opportunities
        ..clear()
        ..addAll(snap.docs.map((d) => Opportunity.fromDoc(d)));
    } catch (e) {
      debugPrint('Error fetching opportunities: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Opportunity?> fetchById(String id) async {
    try {
      final doc = await _oppRef.doc(id).get();
      if (doc.exists) return Opportunity.fromDoc(doc);
    } catch (e) {
      debugPrint('Error fetching opportunity $id: $e');
    }
    return null;
  }

  Future<void> create(Opportunity opp) async {
    try {
      final ref = await _oppRef.add(opp.toMap());
      opp.id = ref.id;
      _opportunities.add(opp);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating opportunity: $e');
    }
  }

  Future<void> update(Opportunity opp) async {
    if (opp.id == null) return;
    try {
      await _oppRef.doc(opp.id).update(opp.toMap());
      final idx = _opportunities.indexWhere((o) => o.id == opp.id);
      if (idx != -1) {
        _opportunities[idx] = opp;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating opportunity: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _oppRef.doc(id).delete();
      _opportunities.removeWhere((o) => o.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting opportunity: $e');
    }
  }
}
