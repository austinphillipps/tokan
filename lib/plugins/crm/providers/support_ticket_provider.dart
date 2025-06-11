// lib/plugins/crm/providers/support_ticket_provider.dart

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/support_ticket.dart';

class SupportTicketProvider extends ChangeNotifier {
  final User _user = FirebaseAuth.instance.currentUser!;
  late final CollectionReference _ticketsRef;

  final List<SupportTicket> _tickets = [];
  List<SupportTicket> get tickets => List.unmodifiable(_tickets);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SupportTicketProvider() {
    // on stocke les tickets sous 'support_tickets' pour plus de clarté
    _ticketsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('support_tickets');
  }

  /// Récupère tous les tickets, du plus récent au plus ancien
  Future<void> fetchAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _ticketsRef
          .orderBy('createdAt', descending: true)
          .get();
      _tickets
        ..clear()
        ..addAll(snapshot.docs.map((d) => SupportTicket.fromDoc(d)));
    } catch (e) {
      debugPrint('Error fetching support tickets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère un ticket par son ID
  Future<SupportTicket?> fetchById(String id) async {
    try {
      final doc = await _ticketsRef.doc(id).get();
      if (!doc.exists) return null;
      return SupportTicket.fromDoc(doc);
    } catch (e) {
      debugPrint('Error fetching support ticket $id: $e');
      return null;
    }
  }

  /// Crée un nouveau ticket et l'ajoute en tête de liste
  Future<void> create(SupportTicket ticket) async {
    try {
      // on s'assure que createdAt et updatedAt sont bien définis
      final data = ticket.toMap();
      data['createdAt'] = ticket.createdAt;
      data['updatedAt'] = ticket.updatedAt;
      final docRef = await _ticketsRef.add(data);
      ticket.id = docRef.id;
      _tickets.insert(0, ticket);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating support ticket: $e');
    }
  }

  /// Met à jour un ticket existant
  Future<void> update(SupportTicket ticket) async {
    if (ticket.id == null) return;
    try {
      // on met à jour la date de modification
      final data = ticket.toMap();
      data['updatedAt'] = DateTime.now();
      await _ticketsRef.doc(ticket.id).update(data);

      final idx = _tickets.indexWhere((t) => t.id == ticket.id);
      if (idx != -1) {
        // on remplace localement l'ancien ticket
        _tickets[idx] = ticket;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating support ticket: $e');
    }
  }

  /// Supprime un ticket
  Future<void> delete(String id) async {
    try {
      await _ticketsRef.doc(id).delete();
      _tickets.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting support ticket: $e');
    }
  }
}
