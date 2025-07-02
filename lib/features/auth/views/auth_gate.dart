// lib/features/auth/views/auth_gate.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../main.dart';                        // pour themeNotifier et AppTheme
import '../../../shared/interface/interface.dart'; // HomeScreen
import '../../../plugins/crm/providers/contact_provider.dart';
import '../../../plugins/crm/providers/opportunity_provider.dart';
import '../../../plugins/crm/providers/quote_provider.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';

/// Widget qui écoute l'état d'authentification et
/// affiche l'écran approprié.
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapAuth) {
        if (snapAuth.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Pas connecté → Login
        final user = snapAuth.data;
        if (user == null) {
          return const LoginPage();
        }

        // Connecté → on récupère le profil Firestore
        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, snapUser) {
            if (snapUser.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = snapUser.data?.data() ?? {};
            final displayName = (data['displayName'] as String?) ?? '';
            final username    = (data['username']    as String?) ?? '';
            final phoneNumber = (data['phoneNumber'] as String?) ?? '';
            final themeStr    = (data['theme']       as String?) ?? '';

            final profileComplete = displayName.isNotEmpty &&
                username.isNotEmpty &&
                phoneNumber.isNotEmpty &&
                themeStr.isNotEmpty;

            if (!profileComplete) {
              // Profil incomplet → setup
              return const ProfileSetupScreen();
            }

            // Synchroniser le thème Firestore → themeNotifier
            try {
              themeNotifier.value = AppTheme.values
                  .firstWhere((e) => e.toString() == themeStr);
            } catch (_) {
              // Valeur inconnue, on laisse le thème actuel
            }

            // Profil complet → initialisation des providers, puis HomeScreen
            return MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => ContactProvider()),
                ChangeNotifierProvider(create: (_) => OpportunityProvider()),
                ChangeNotifierProvider(create: (_) => QuoteProvider()),
                // … autres providers éventuels …
              ],
              child: const HomeScreen(),
            );
          },
        );
      },
    );
  }
}
