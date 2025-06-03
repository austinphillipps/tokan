// lib/features/auth/services/auth_service.dart

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  // 1) Constructeur privé
  AuthService._privateConstructor();

  // 2) Instance statique unique (singleton)
  static final AuthService instance = AuthService._privateConstructor();

  // 3) Champs privés Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Retourne l'utilisateur actuellement connecté (ou null si non connecté)
  User? get currentUser => _auth.currentUser;

  /// Met à jour le displayName (pseudo) de l’utilisateur courant
  Future<void> updateDisplayName(String newName) async {
    final user = currentUser;
    if (user == null) {
      throw Exception("Aucun utilisateur connecté.");
    }
    await user.updateDisplayName(newName);
    await user.reload();
  }

  /// Met à jour la photo de profil de l’utilisateur courant à partir du [imageFile]
  Future<void> updatePhoto(File imageFile) async {
    final user = currentUser;
    if (user == null) {
      throw Exception("Aucun utilisateur connecté.");
    }

    final uid = user.uid;
    // On crée une référence dans Firebase Storage
    final storageRef = _storage.ref().child('user_photos/$uid.jpg');

    // On charge le fichier
    final uploadTask = storageRef.putFile(imageFile);
    final snapshot = await uploadTask;

    // On récupère l'URL de téléchargement
    final photoURL = await snapshot.ref.getDownloadURL();

    // On met à jour le photoURL de l'utilisateur dans Firebase Auth
    await user.updatePhotoURL(photoURL);
    await user.reload();
  }

  /// Envoie un email de réinitialisation de mot de passe à [email]
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// (Exemple de méthode supplémentaire pour la déconnexion)
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// (Exemple de méthode supplémentaire pour la connexion par email/mot de passe)
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// (Exemple de méthode supplémentaire pour l’inscription par email/mot de passe)
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }
}
