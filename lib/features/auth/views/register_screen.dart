import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// 🔄 Redirection vers l’interface principale de Sequoia
import '../../../shared/interface/interface.dart'; // ajuste le chemin si besoin

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _displayNameCtrl = TextEditingController();
  final _usernameCtrl    = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _passwordCtrl    = TextEditingController();
  final _confirmCtrl     = TextEditingController();

  bool _showPassword = false;
  bool _showConfirm  = false;
  final _formKey     = GlobalKey<FormState>();
  String? _errorMessage;

  final RegExp emailRegex    = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
  final RegExp passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*\d).{6,}$');

  @override
  void initState() {
    super.initState();
    // Si déjà authentifié, on va direct sur HomeScreen
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      });
    }
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Inscription',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // — Nom complet (displayName)
                    _buildTextField(
                      label: 'Nom complet',
                      controller: _displayNameCtrl,
                      obscure: false,
                      validator: (v) => v == null || v.isEmpty
                          ? "Veuillez entrer votre nom complet."
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // — Nom d’utilisateur
                    _buildTextField(
                      label: 'Nom d’utilisateur',
                      controller: _usernameCtrl,
                      obscure: false,
                      validator: (v) => v == null || v.isEmpty
                          ? "Veuillez choisir un nom d’utilisateur."
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // — Email
                    _buildTextField(
                      label: 'Email',
                      controller: _emailCtrl,
                      obscure: false,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Veuillez entrer un email.";
                        if (!emailRegex.hasMatch(v)) return "Format d'email invalide.";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // — Mot de passe
                    _buildTextField(
                      label: 'Mot de passe',
                      controller: _passwordCtrl,
                      obscure: !_showPassword,
                      suffix: IconButton(
                        icon: Icon(
                          _showPassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Entrez un mot de passe.";
                        if (!passwordRegex.hasMatch(v)) {
                          return "Min. 6 caractères, 1 majuscule, 1 chiffre.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // — Confirmation mot de passe
                    _buildTextField(
                      label: 'Confirmez le mot de passe',
                      controller: _confirmCtrl,
                      obscure: !_showConfirm,
                      suffix: IconButton(
                        icon: Icon(
                          _showConfirm ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () => setState(() => _showConfirm = !_showConfirm),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Confirmez votre mot de passe.";
                        if (v != _passwordCtrl.text) {
                          return "Les mots de passe ne correspondent pas.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // — Message d'erreur
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // — Bouton Inscription
                    SizedBox(
                      width: 250,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: const Text('S’inscrire'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        "Déjà un compte ? Connectez-vous.",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white38),
          borderRadius: BorderRadius.circular(50),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(50),
        ),
        suffixIcon: suffix,
      ),
    );
  }

  Future<void> _register() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    try {
      // 1️⃣ Création du compte Firebase Auth
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      final user = credential.user;

      if (user != null) {
        // 2️⃣ Création du profil utilisateur en Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'email':       user.email,
          'displayName': _displayNameCtrl.text.trim(),
          'username':    _usernameCtrl.text.trim(),
          'createdAt':   FieldValue.serverTimestamp(),
        });
      }

      // 3️⃣ Redirection vers HomeScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _errorMessage = "Cet email est déjà utilisé.";
            break;
          case 'invalid-email':
            _errorMessage = "Email invalide.";
            break;
          case 'weak-password':
            _errorMessage = "Mot de passe trop faible.";
            break;
          default:
            _errorMessage = "Erreur : ${e.message}";
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur inattendue : ${e.toString()}";
      });
    }
  }
}
