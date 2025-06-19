// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';

// ───────────── Nouveaux imports ─────────────
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// Vos providers existants
import 'core/providers/plugin_provider.dart';
import 'features/dashboard/providers/dashboard_widget_provider.dart';
import 'features/dashboard/widgets/project_progress_widget.dart';

import 'features/auth/services/auth_service.dart';
import 'features/auth/views/login_screen.dart';
import 'features/auth/views/register_screen.dart';
import 'features/auth/views/auth_gate.dart';
import 'shared/interface/interface.dart'; // Pour HomeScreen
import 'firebase_options.dart';

/// 1) Enum à trois valeurs
enum AppTheme { light, dark, sequoia }

/// 2) ValueNotifier global, initialisé à Clair (sera écrasé si prefs contient autre chose)
final ValueNotifier<AppTheme> themeNotifier = ValueNotifier(AppTheme.light);

/// Image de fond configurable
final ValueNotifier<String> backgroundImageNotifier =
    ValueNotifier('assets/images/sequoia.jpeg');

/// 3) Classe centralisant toutes les couleurs utilisées dans l’app
class AppColors {
  static const Color darkBackground      = Color(0xFF212121);
  static const Color darkGreyBackground  = Color(0xFF424242);
  static const Color lightGreyBackground = Color(0xFFF5F5F5);
  static const Color tealEnergy          = Color(0xFF1ABC9C);
  static const Color green               = Color(0xFF4CAF50);
  static const Color purple              = Color(0xFF6750A4);
  static const Color blue                = tealEnergy;
  static const Color glassHeader         = Color(0x66000000);
  static const Color glassBackground     = Color(0x33000000);
}

/// 4) Définition du thème clair
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  // Use a transparent scaffold background so the optional background image
  // remains visible. Widgets will therefore have transparent backgrounds
  // unless otherwise specified.
  scaffoldBackgroundColor: Colors.transparent,
  colorScheme: const ColorScheme.light(
    primary: AppColors.blue,
    secondary: AppColors.green,
    background: Colors.white,
    onBackground: Colors.black,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.blue,
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.blue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: AppColors.blue),
  ),
  iconTheme: const IconThemeData(color: AppColors.blue),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedIconTheme: IconThemeData(color: AppColors.blue),
    unselectedIconTheme: IconThemeData(color: Colors.grey),
    backgroundColor: AppColors.darkBackground,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.all(AppColors.green),
    trackColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return AppColors.green.withOpacity(0.5);
      }
      return null;
    }),
  ),
  checkboxTheme: CheckboxThemeData(
    checkColor: MaterialStateProperty.all(Colors.white),
    fillColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return AppColors.green;
      }
      return null;
    }),
  ),
);

/// 5) Définition du thème sombre
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.darkBackground,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.blue,
    secondary: AppColors.green,
    background: AppColors.darkBackground,
    surface: AppColors.darkBackground,
    onBackground: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkGreyBackground,
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.blue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: AppColors.blue),
  ),
  iconTheme: const IconThemeData(color: AppColors.blue),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedIconTheme: IconThemeData(color: AppColors.blue),
    unselectedIconTheme: IconThemeData(color: Colors.grey),
    backgroundColor: AppColors.darkBackground,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.all(AppColors.green),
    trackColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return AppColors.green.withOpacity(0.5);
      }
      return null;
    }),
  ),
  checkboxTheme: CheckboxThemeData(
    checkColor: MaterialStateProperty.all(Colors.white),
    fillColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return AppColors.green;
      }
      return null;
    }),
  ),
);

/// 6) Définition du thème Sequoia (verre dépoli)
final ThemeData sequoiaTheme = darkTheme.copyWith(
  scaffoldBackgroundColor: Colors.transparent,
  canvasColor: Colors.black.withOpacity(0.5),
  cardColor: Colors.black.withOpacity(0.5),
  dialogBackgroundColor: Colors.black.withOpacity(0.5),
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: Colors.black.withOpacity(0.5),
  ),
  listTileTheme: ListTileThemeData(
    tileColor: Colors.black.withOpacity(0.5),
    iconColor: Colors.white,
    textColor: Colors.white,
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: Colors.black.withOpacity(0.5),
    textStyle: const TextStyle(color: Colors.white),
  ),
  chipTheme: ChipThemeData.fromDefaults(
    secondaryColor: Colors.black.withOpacity(0.5),
    brightness: Brightness.dark,
    labelStyle: const TextStyle(color: Colors.white),
  ).copyWith(backgroundColor: Colors.black.withOpacity(0.5)),
  appBarTheme: darkTheme.appBarTheme.copyWith(
    backgroundColor: Colors.black54,
    foregroundColor: Colors.white,
  ),
  bottomNavigationBarTheme:
  darkTheme.bottomNavigationBarTheme.copyWith(
    backgroundColor: Colors.black.withOpacity(0.5),
  ),
  navigationRailTheme:
  darkTheme.navigationRailTheme.copyWith(
    backgroundColor: Colors.black.withOpacity(0.5),
  ),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('fr_FR', null);

  // ───────────── Charger le thème sauvegardé ─────────────
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString('appTheme');
  if (stored != null) {
    themeNotifier.value = AppTheme.values.firstWhere(
          (e) => e.toString() == stored,
      orElse: () => AppTheme.light,
    );
  }

  // Charger l'image de fond en fonction du thème
  final storedBg = prefs.getString('backgroundImage');
  if (themeNotifier.value == AppTheme.sequoia) {
    backgroundImageNotifier.value = 'assets/images/sequoia.jpeg';
  } else {
    backgroundImageNotifier.value =
        storedBg ?? 'assets/images/sequoia.jpeg';
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PluginProvider()),
        ChangeNotifierProvider(
          create: (_) => DashboardWidgetProvider()
            ..addWidget(const ProjectProgressWidget()),
        ),
        // Les providers dépendant de l'utilisateur seront instanciés
        // plus tard, une fois authentifié, pour éviter les erreurs.
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: themeNotifier,
      builder: (context, currentAppTheme, child) {
        ThemeData themeToApply;
        switch (currentAppTheme) {
          case AppTheme.light:
            themeToApply = lightTheme;
            break;
          case AppTheme.dark:
            themeToApply = darkTheme;
            break;
          case AppTheme.sequoia:
            themeToApply = sequoiaTheme;
            break;
        }

        return MaterialApp(
          title: 'Mon App',
          debugShowCheckedModeBanner: false,
          theme: themeToApply,
          home: const AuthGate(),
          routes: {
            '/login':    (_) => const LoginPage(),
            '/register': (_) => const RegisterPage(),
            '/home':     (_) => const HomeScreen(),
            // Les routes CRM / FSM / ESP sont gérées dynamiquement via PluginProvider
          },
        );
      },
    );
  }
}