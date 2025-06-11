import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/campaign.dart';

class CampaignProvider extends ChangeNotifier {
  final User _user = FirebaseAuth.instance.currentUser!;
  late final CollectionReference _ref;

  final List<Campaign> _campaigns = [];
  List<Campaign> get campaigns => List.unmodifiable(_campaigns);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  CampaignProvider() {
    _ref = FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('campaigns');
  }

  Future<void> fetchAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await _ref.orderBy('startDate', descending: true).get();
      _campaigns
        ..clear()
        ..addAll(snap.docs.map((d) => Campaign.fromDoc(d)));
    } catch (e) {
      debugPrint('Error fetching campaigns: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Campaign?> fetchById(String id) async {
    try {
      final doc = await _ref.doc(id).get();
      if (doc.exists) return Campaign.fromDoc(doc);
    } catch (e) {
      debugPrint('Error fetching campaign $id: $e');
    }
    return null;
  }

  Future<void> create(Campaign c) async {
    try {
      final doc = await _ref.add(c.toMap());
      c.id = doc.id;
      _campaigns.insert(0, c);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating campaign: $e');
    }
  }

  Future<void> update(Campaign c) async {
    if (c.id == null) return;
    try {
      await _ref.doc(c.id).update(c.toMap());
      final idx = _campaigns.indexWhere((e) => e.id == c.id);
      if (idx != -1) {
        _campaigns[idx] = c;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating campaign: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _ref.doc(id).delete();
      _campaigns.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting campaign: $e');
    }
  }
}
