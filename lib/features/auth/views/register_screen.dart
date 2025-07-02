import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_gate.dart';
// 🔄 Redirection vers l’interface principale de Sequoia
import '../../../shared/interface/interface.dart'; // ajuste le chemin si besoin
import '../../../main.dart'; // Pour AppTheme et themeNotifier
import 'profile_setup_screen.dart'; // écran de configuration du profil

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _loading     = false;
  String? _errorMessage;

  bool _showPassword = false;
  bool _showConfirm  = false;

  final RegExp emailRegex    = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
  final RegExp passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*\d).{6,}$');

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget form = Form(
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
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(
            width: 250,
            child: ElevatedButton(
              onPressed: _loading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('S’inscrire'),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loading ? null : () => Navigator.of(context).pop(),
            child: const Text(
              "Déjà un compte ? Connectez-vous.",
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/sequoia.jpeg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: form,
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
    setState(() {
      _errorMessage = null;
      _loading = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() => _loading = false);
      return;
    }

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    try {
      print('📝 [RegisterPage] register() called with email: $email');

      // 1️⃣ Création du compte Firebase Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      print('✅ [RegisterPage] Auth createUser success, uid=${user?.uid}');
      if (user == null) {
        throw FirebaseAuthException(
          code: 'unknown',
          message: 'Échec de la création du compte.',
        );
      }

      // 2️⃣ Création du document utilisateur en Firestore
      print('📝 [RegisterPage] creating Firestore user doc for uid=${user.uid}');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ [RegisterPage] Firestore user doc created');

      // 3️⃣ Redirection vers l'écran de configuration du profil
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
        );
      }
    } on FirebaseAuthException catch (e, st) {
      print('❌ [RegisterPage] FirebaseAuthException: $e');
      print(st);
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
    } catch (e, st) {
      print('❌ [RegisterPage] Unexpected error: $e');
      print(st);
      setState(() {
        _errorMessage = "Erreur inattendue : ${e.toString()}";
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
