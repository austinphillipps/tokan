// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';

// ───────────── Nouveaux imports pour Provider ─────────────
import 'package:provider/provider.dart';
import 'core/providers/plugin_provider.dart';

// Import du StockProvider
import 'plugins/stock/providers/stock_provider.dart';

import 'features/auth/services/auth_service.dart';
import 'features/auth/views/login_screen.dart';
import 'features/auth/views/register_screen.dart';
import 'shared/interface/interface.dart';
import 'firebase_options.dart';

/// 1) On crée un ValueNotifier global pour piloter le ThemeMode de l'app.
///    Par défaut, on reste en thème sombre.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

/// 2) Classe centralisant toutes les couleurs utilisées dans l'app
///    pour pouvoir les réutiliser facilement dans les Themes et composants.
class AppColors {
  /// Fond sombre principal (gris cendres)
  static const Color darkBackground = Color(0xFF212121);

  /// Nouveau gris foncé (#424242) pour certains fonds d'éléments en sombre
  static const Color darkGreyBackground = Color(0xFF424242);

  /// Bleu « actif » (icônes, sélection, etc.)
  static const Color blue = Color(0xFF448AFF);

  /// Validation (boutons ou icônes de validation) en vert
  static const Color green = Color(0xFF4CAF50);

  /// Couleur « principale » pour certains boutons (violet)
  static const Color purple = Color(0xFF6750A4);

  /// Nouveau gris clair pour certains fonds en mode clair (#F2F2F2)
  static const Color lightGreyBackground = Color(0xFFF2F2F2);
}

/// 3) Thème clair de l’application
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,

  // Fond général en blanc
  scaffoldBackgroundColor: Colors.white,

  // Définition du ColorScheme clair
  colorScheme: const ColorScheme.light(
    primary: AppColors.purple,     // violet → boutons principaux
    secondary: AppColors.blue,     // bleu   → éléments « actifs »
    background: Colors.white,
    onBackground: Colors.black,    // texte sur fond blanc
    onPrimary: Colors.white,       // texte sur violet
    onSecondary: Colors.white,     // texte sur bleu
  ),

  // ElevatedButton principal en violet (background), texte blanc
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.purple,
      foregroundColor: Colors.white,
    ),
  ),

  // TextButton par défaut (par exemple pour boutons de validation) en vert
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.green,
    ),
  ),

  // Icônes par défaut en bleu
  iconTheme: const IconThemeData(color: AppColors.blue),

  // BottomNavigationBar : icône sélectionnée en bleu, désélectionnée en gris
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedIconTheme: IconThemeData(color: AppColors.blue),
    unselectedIconTheme: IconThemeData(color: Colors.grey),
    backgroundColor: Colors.white,
  ),

  // Switch & Checkbox : couleur active en vert
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.all(AppColors.green),
    trackColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return AppColors.green.withOpacity(0.5);
      }
      return Colors.grey.withOpacity(0.5);
    }),
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: MaterialStateProperty.all(AppColors.green),
  ),

  // Exemple : Card sur thème clair (fond blanc, ombre légère)
  cardColor: Colors.white,
);

/// 4) Thème sombre de l’application
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,

  // Fond général en gris cendres
  scaffoldBackgroundColor: AppColors.darkBackground,

  // Définition du ColorScheme sombre
  colorScheme: const ColorScheme.dark(
    primary: AppColors.blue,         // bleu   → icônes « actives »
    secondary: AppColors.purple,     // violet → boutons dans le dark
    background: AppColors.darkBackground,
    surface: AppColors.darkBackground,
    onBackground: Colors.white,      // texte sur fond sombre
    onPrimary: Colors.white,         // texte sur bleu
    onSecondary: Colors.white,       // texte sur violet
  ),

  // ElevatedButton principal en violet (background), texte blanc
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.purple,
      foregroundColor: Colors.white,
    ),
  ),

  // TextButton par défaut (par exemple pour boutons de validation) en vert
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.green,
    ),
  ),

  // Icônes par défaut en bleu
  iconTheme: const IconThemeData(color: AppColors.blue),

  // BottomNavigationBar : icône sélectionnée en bleu, désélectionnée en gris
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedIconTheme: IconThemeData(color: AppColors.blue),
    unselectedIconTheme: IconThemeData(color: Colors.grey),
    backgroundColor: AppColors.darkBackground,
  ),

  // Switch & Checkbox : couleur active en vert
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.all(AppColors.green),
    trackColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return AppColors.green.withOpacity(0.5);
      }
      return Colors.grey.withOpacity(0.5);
    }),
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: MaterialStateProperty.all(AppColors.green),
  ),

  // Pour certains Card ou Dialog en sombre, on souhaite utiliser le gris #424242
  cardColor: AppColors.darkGreyBackground,
  dialogBackgroundColor: AppColors.darkGreyBackground,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialisation des locales pour Intl (ici en français)
  await initializeDateFormatting('fr_FR', null);

  // ─────────── On enveloppe l’application dans MultiProvider ───────────
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PluginProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
        // … d’autres providers éventuels
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // On écoute le themeNotifier pour basculer entre light et dark
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeMode, child) {
        final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
        return MaterialApp(
          title: 'Mon App',
          debugShowCheckedModeBanner: false,

          // On connecte nos deux thèmes
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: currentThemeMode,

          // Home / routing
          home: isLoggedIn ? const HomeScreen() : const LoginPage(),
          routes: {
            '/login': (_) => const LoginPage(),
            '/register': (_) => const RegisterPage(),
            '/home': (_) => const HomeScreen(),
            // Ajoutez d’autres routes au besoin
          },
        );
      },
    );
  }
}
