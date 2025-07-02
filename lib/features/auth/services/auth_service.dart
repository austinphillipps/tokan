/// lib/features/auth/services/auth_service.dart

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // 1) Constructeur privé
  AuthService._privateConstructor();

  // 2) Instance statique unique (singleton)
  static final AuthService instance = AuthService._privateConstructor();

  // 3) Champs privés Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Retourne l’utilisateur actuellement connecté (ou null si non connecté)
  User? get currentUser => _auth.currentUser;

  /// Met à jour le displayName (pseudo) de l’utilisateur courant
  Future<void> updateDisplayName(String newName) async {
    final user = currentUser;
    if (user == null) throw Exception("Aucun utilisateur connecté.");
    await user.updateDisplayName(newName);
    await user.reload();
  }

  /// Met à jour la photo de profil de l’utilisateur courant à partir du [imageFile]
  Future<void> updatePhoto(File imageFile) async {
    final user = currentUser;
    if (user == null) throw Exception("Aucun utilisateur connecté.");

    final uid = user.uid;
    final storageRef = _storage.ref().child('user_photos/$uid.jpg');
    final snapshot = await storageRef.putFile(imageFile);
    final photoURL = await snapshot.ref.getDownloadURL();
    await user.updatePhotoURL(photoURL);
    await user.reload();
  }

  /// Met à jour les données utilisateur dans la collection `users`
  Future<void> updateUserData(Map<String, dynamic> data) async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('Aucun utilisateur connecté.');
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  /// Sauvegarde tout le profil issu du formulaire
  Future<void> saveUserProfile({
    required String lastName,
    required String firstName,
    required String username,
    required String phone,
    required String theme,
  }) async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('Aucun utilisateur connecté.');

    final displayName = '$firstName $lastName';
    // Met à jour le displayName dans Firebase Auth
    await updateDisplayName(displayName);

    // Met à jour tous les champs en base Firestore
    await updateUserData({
      'displayName': displayName,
      'username': username,
      'phoneNumber': phone,
      'theme': theme,
    });
  }

  /// Envoie un email de réinitialisation de mot de passe à [email]
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print('✉️ [AuthService] sendPasswordResetEmail called for $email');
      await _auth.sendPasswordResetEmail(email: email);
      print('✅ [AuthService] sendPasswordResetEmail success for $email');
    } catch (e, st) {
      print('❌ [AuthService] sendPasswordResetEmail ERROR: $e');
      print(st);
      rethrow;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      print('🔓 [AuthService] signOut called');
      await _auth.signOut();
      print('✅ [AuthService] signOut success');
    } catch (e, st) {
      print('❌ [AuthService] signOut ERROR: $e');
      print(st);
      rethrow;
    }
  }

  /// Connexion par email/mot de passe
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('🔑 [AuthService] signInWithEmailAndPassword called with email: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ [AuthService] signIn success, uid=${credential.user?.uid}');
      return credential;
    } catch (e, st) {
      print('❌ [AuthService] signIn ERROR: $e');
      print(st);
      rethrow;
    }
  }

  /// Inscription par email/mot de passe
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('🔨 [AuthService] createUser called with email: $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ [AuthService] createUser success, uid=${credential.user?.uid}');
      return credential;
    } catch (e, st) {
      print('❌ [AuthService] createUser ERROR: $e');
      print(st);
      rethrow;
    }
  }
}
