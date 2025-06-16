import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint, debugPrintStack;
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';
import '../../../shared/interface/interface.dart'; // Ajuste le chemin si besoin

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showPassword = false;
  String? _errorMessage;

  final _emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");

  @override
  void initState() {
    super.initState();
    // Si l'utilisateur est déjà connecté, on saute l'écran de login
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
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      // FirebaseAuth conserve automatiquement la session
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e, st) {
      debugPrint('🔥 FirebaseAuthException: code=${e.code} message=${e.message}');
      debugPrintStack(stackTrace: st);
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _errorMessage = "Aucun utilisateur trouvé avec cet email.";
            break;
          case 'wrong-password':
            _errorMessage = "Mot de passe incorrect.";
            break;
          default:
            _errorMessage =
            "Impossible de vous connecter. Vérifiez vos informations.";
        }
      });
    } catch (e, st) {
      debugPrint('❗️ Erreur inattendue: $e');
      debugPrintStack(stackTrace: st);
      setState(() => _errorMessage =
      "Erreur inattendue. Veuillez réessayer et consultez la console.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = [
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.macOS,
    ].contains(defaultTargetPlatform);

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
                      'Connexion',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // — Email
                    _buildTextField(
                      label: 'Email',
                      controller: _emailCtrl,
                      obscure: false,
                      inputAction: TextInputAction.next,
                      onSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Entrez un email.";
                        }
                        if (!_emailRegex.hasMatch(value)) {
                          return "Format d'email invalide.";
                        }
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
                          _showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Entrez un mot de passe.";
                        }
                        return null;
                      },
                      inputAction: TextInputAction.done,
                      onSubmitted: (_) => _login(),
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

                    // — Bouton Connexion
                    SizedBox(
                      width: 250,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: const Text('Se connecter'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).push(_createRoute()),
                      child: const Text(
                        "Pas encore de compte ? Créez-en un.",
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
    TextInputAction? inputAction,
    void Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      textInputAction: inputAction,
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white10,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (_, animation, __) => const RegisterPage(),
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (_, animation, __, child) {
        final fade =
        CurvedAnimation(parent: animation, curve: Curves.easeInOut);
        final scale = Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.elasticOut),
        );
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }
}