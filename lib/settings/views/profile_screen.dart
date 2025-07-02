// lib/settings/views/profile_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/auth/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _authUser = AuthService.instance.currentUser;

  // Pour l’avatar :
  File? _imageFile;
  bool _isLoading = false;

  // Pour afficher le pseudo (username depuis Firestore) :
  String _username = '';
  // Pour modifier le pseudo dans le dialog :
  late TextEditingController _usernameController;

  // Pour les champs de réinitialisation du mot de passe :
  final TextEditingController _currentPwdController = TextEditingController();
  final TextEditingController _newPwdController = TextEditingController();
  final TextEditingController _confirmPwdController = TextEditingController();

  // Pour gérer l’expansion de la section mot de passe :
  bool _showPasswordSection = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _loadCurrentUserInfo();
  }

  Future<void> _loadCurrentUserInfo() async {
    if (_authUser == null) return;

    // 1. Charger le username depuis Firestore :
    final doc = await _firestore.collection('users').doc(_authUser!.uid).get();
    final data = doc.data();
    String fetchedUsername = '';
    if (data != null && data.containsKey('username')) {
      fetchedUsername = (data['username'] as String).trim();
    }
    setState(() {
      _username = fetchedUsername.isNotEmpty ? fetchedUsername : 'Utilisateur';
      _usernameController.text = _username;
    });
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _isLoading = true;
      });
      try {
        // Upload immédiat de la photo
        await AuthService.instance.updatePhoto(_imageFile!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar mis à jour')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour : $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editUsername() async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier le pseudo'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Nouveau pseudo',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final candidate = _usernameController.text.trim();
                Navigator.of(context).pop(candidate.isEmpty ? null : candidate);
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName != _username && _authUser != null) {
      setState(() => _isLoading = true);
      try {
        // 1. Mettre à jour le displayName dans FirebaseAuth
        await AuthService.instance.updateDisplayName(newName);

        // 2. Mettre à jour le champ 'username' dans Firestore
        await _firestore.collection('users').doc(_authUser!.uid).update({
          'username': newName,
        });

        setState(() => _username = newName);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pseudo mis à jour')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour : $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _changePassword() async {
    final currentPwd = _currentPwdController.text;
    final newPwd = _newPwdController.text;
    final confirmPwd = _confirmPwdController.text;

    if (_authUser == null) return;

    // Validations
    if (currentPwd.isEmpty || newPwd.isEmpty || confirmPwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }
    if (newPwd != confirmPwd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }
    if (newPwd.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le mot de passe doit avoir au moins 6 caractères')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Réauthentifier l’utilisateur
      final credential = EmailAuthProvider.credential(
        email: _authUser!.email!,
        password: currentPwd,
      );
      await _authUser!.reauthenticateWithCredential(credential);

      // Mettre à jour le mot de passe
      await _authUser!.updatePassword(newPwd);

      // Vider les champs
      _currentPwdController.clear();
      _newPwdController.clear();
      _confirmPwdController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe mis à jour')),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Erreur lors du changement de mot de passe';
      if (e.code == 'wrong-password') {
        message = 'Le mot de passe actuel est incorrect';
      } else if (e.code == 'weak-password') {
        message = 'Le nouveau mot de passe est trop faible';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur inattendue : $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPwdController.dispose();
    _newPwdController.dispose();
    _confirmPwdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ------------ Avatar ------------
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (_authUser?.photoURL != null
                            ? NetworkImage(_authUser!.photoURL!) as ImageProvider
                            : const AssetImage('assets/avatar_placeholder.png')),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isLoading ? null : _pickAndUploadImage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ------------ Pseudo + Bouton Modifier ------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 250),
                      child: Text(
                        _username,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      color: Colors.white, // icône blanche pour visibilité
                      onPressed: _isLoading ? null : _editUsername,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ------------ Section Réinitialiser Mot de Passe ------------
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showPasswordSection = !_showPasswordSection;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Réinitialiser le mot de passe',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(
                              _showPasswordSection
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: theme.iconTheme.color,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Si l’utilisateur a cliqué, on affiche le formulaire :
                if (_showPasswordSection)
                  Center(
                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                        child: Column(
                          children: [
                            // Mot de passe actuel
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 350),
                              child: TextField(
                                controller: _currentPwdController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Mot de passe actuel',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.lock_outline),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Nouveau mot de passe
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 350),
                              child: TextField(
                                controller: _newPwdController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Nouveau mot de passe',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.vpn_key),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Confirmer le mot de passe
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 350),
                              child: TextField(
                                controller: _confirmPwdController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Confirmer le mot de passe',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Bouton Valider le changement
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _changePassword,
                                child: const Text('Mettre à jour'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                                  tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Indicateur de chargement semi-transparent
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
