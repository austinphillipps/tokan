import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestsPage extends StatefulWidget {
  @override
  _FriendRequestsPageState createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  Future<void> _acceptRequest(String requestId, Map<String, dynamic> requestData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final currentUserDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final senderUid = requestData['senderUid'];
    final senderEmail = requestData['senderEmail'];
    String senderDisplayName = (requestData['senderDisplayName'] as String?)?.trim() ?? '';
    if (senderDisplayName.isEmpty) {
      senderDisplayName = senderEmail;
    }
    await currentUserDoc.collection('friend_requests').doc(requestId).update({'status': 'accepted'});
    await currentUserDoc.collection('collaborators').doc(senderUid).set({
      'uid': senderUid,
      'email': senderEmail,
      'displayName': senderDisplayName,
      'addedAt': FieldValue.serverTimestamp(),
    });
    String currentUserDisplayName = (user.displayName ?? '').trim();
    if (currentUserDisplayName.isEmpty) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      currentUserDisplayName = ((userDoc.data() as Map<String, dynamic>)['displayName'] ?? user.email) as String;
    }
    await FirebaseFirestore.instance.collection('users').doc(senderUid)
        .collection('collaborators')
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'email': user.email,
      'displayName': currentUserDisplayName,
      'addedAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Demande acceptée")),
    );
  }

  Future<void> _rejectRequest(String requestId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final currentUserDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await currentUserDoc.collection('friend_requests').doc(requestId).update({'status': 'rejected'});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Demande rejetée")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text("Utilisateur non connecté", style: TextStyle(color: Colors.white70)));
    }
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text("Demandes d'amis"),
        backgroundColor: Colors.grey[800],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('friend_requests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final requests = snapshot.data!.docs;
          if (requests.isEmpty) return Center(child: Text("Aucune demande en attente", style: TextStyle(color: Colors.white70)));
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final requestDoc = requests[index];
              final data = requestDoc.data() as Map<String, dynamic>;
              String senderEmail = data['senderEmail'] ?? 'Inconnu';
              String senderDisplayName = (data['senderDisplayName'] as String?)?.trim() ?? '';
              if (senderDisplayName.isEmpty) {
                senderDisplayName = senderEmail;
              }
              return Card(
                color: Colors.grey[850],
                child: ListTile(
                  title: Text(senderDisplayName, style: TextStyle(color: Colors.white)),
                  subtitle: Text(senderEmail, style: TextStyle(color: Colors.white70)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () => _acceptRequest(requestDoc.id, data),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () => _rejectRequest(requestDoc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
