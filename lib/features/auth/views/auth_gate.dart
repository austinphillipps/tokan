import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../shared/interface/interface.dart';
import '../../../plugins/crm/providers/contact_provider.dart';
import '../../../plugins/crm/providers/opportunity_provider.dart';
import '../../../plugins/crm/providers/quote_provider.dart';
import 'login_screen.dart';

/// Widget qui écoute l'état d'authentification pour
/// afficher l'écran approprié.
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == null) {
          return const LoginPage();
        }

        // L'utilisateur est connecté : on instancie ici les providers
        // dépendant de son UID afin d'éviter des erreurs avant authentification.
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ContactProvider()),
            ChangeNotifierProvider(create: (_) => OpportunityProvider()),
            ChangeNotifierProvider(create: (_) => QuoteProvider()),
            // … ajoutez d'autres providers liés à l'utilisateur ici …
          ],
          child: const HomeScreen(),
        );
      },
    );
  }
}
