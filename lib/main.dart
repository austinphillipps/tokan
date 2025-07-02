// lib/main.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show consolidateHttpClientResponseBytes;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'firebase_options.dart';
import 'core/providers/plugin_provider.dart';
import 'features/dashboard/providers/dashboard_widget_provider.dart';
import 'features/dashboard/widgets/project_progress_widget.dart';
import 'features/auth/views/login_screen.dart';
import 'features/auth/views/register_screen.dart';
import 'features/auth/views/auth_gate.dart';
import 'features/auth/views/profile_setup_screen.dart'; // ajouté pour la config de profil
import 'shared/interface/interface.dart'; // HomeScreen

// ← IMPORT DU UpdateManager
import 'services/update_manager.dart';

/// 1) Enum à trois valeurs (clair, sombre, séquoia)
enum AppTheme { light, dark, sequoia }

/// 2) ValueNotifier global pour le thème
final ValueNotifier<AppTheme> themeNotifier = ValueNotifier(AppTheme.light);

/// 3) Couleurs de l’app
class AppColors {
  static const Color darkBackground       = Color(0xFF212121);
  static const Color darkGreyBackground   = Color(0xFF424242);
  static const Color lightGreyBackground  = Color(0xFFF5F5F5);
  static const Color tealEnergy           = Color(0xFF1ABC9C);
  static const Color green                = Color(0xFF4CAF50);
  static const Color purple               = Color(0xFF6750A4);
  static const Color blue                 = tealEnergy;
  static const Color glassHeader          = Color(0x66000000);
  static const Color glassBackground      = Color(0x33000000);
  static const Color whiteGlassHeader     = Color(0xFFE0E0E0);
  static const Color whiteGlassBackground = Color(0x55FFFFFF);
}

/// 4) Thème clair
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: AppColors.blue,
    secondary: AppColors.green,
    background: AppColors.lightGreyBackground,
    surface: Colors.white,
    onBackground: Colors.black,
    onSurface: Colors.black,
    onPrimary: Colors.black,
    onSecondary: Colors.black,
  ),
  canvasColor: Colors.white,
  cardColor: Colors.white,
  dialogBackgroundColor: Colors.white,
  bottomSheetTheme: BottomSheetThemeData(backgroundColor: Colors.white),
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
  iconTheme: const IconThemeData(color: Colors.black),
  textTheme: ThemeData.light().textTheme.apply(
    bodyColor: Colors.black,
    displayColor: Colors.black,
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

/// 5) Thème sombre
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

/// 6) Thème Séquoia (verre dépoli)
final ThemeData sequoiaTheme = darkTheme.copyWith(
  scaffoldBackgroundColor: Colors.transparent,
  canvasColor: Colors.black.withOpacity(0.5),
  cardColor: Colors.black.withOpacity(0.5),
  dialogBackgroundColor: Colors.black.withOpacity(0.5),
  bottomSheetTheme: BottomSheetThemeData(backgroundColor: Colors.black.withOpacity(0.5)),
  listTileTheme: const ListTileThemeData(
    tileColor: Colors.black54,
    iconColor: Colors.white,
    textColor: Colors.white,
  ),
  popupMenuTheme: const PopupMenuThemeData(
    color: Colors.black54,
    textStyle: TextStyle(color: Colors.white),
  ),
  chipTheme: const ChipThemeData(
    backgroundColor: Colors.black54,
    disabledColor: Colors.black26,
    selectedColor: Colors.black54,
    secondarySelectedColor: Colors.black54,
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    labelStyle: TextStyle(color: Colors.white),
    secondaryLabelStyle: TextStyle(color: Colors.white),
    brightness: Brightness.dark,
  ),
  appBarTheme: darkTheme.appBarTheme.copyWith(
    backgroundColor: Colors.black54,
    foregroundColor: Colors.white,
  ),
  bottomNavigationBarTheme:
  darkTheme.bottomNavigationBarTheme.copyWith(backgroundColor: Colors.black54),
  navigationRailTheme:
  darkTheme.navigationRailTheme.copyWith(backgroundColor: Colors.black54),
);

/// 7) Service de mise à jour Windows
class UpdateService {
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse('https://tonsite.com/version.json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final latestVersion = data['latest_version'] as String;
        final exeUrl = data['exe_url'] as String;
        final info = await PackageInfo.fromPlatform();
        if (info.version != latestVersion) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Mise à jour disponible'),
              content:
              const Text('Une nouvelle version est disponible. Voulez-vous l’installer ?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Plus tard')),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final tmp = await getTemporaryDirectory();
                    final path = '${tmp.path}/installer.exe';
                    final req = await HttpClient().getUrl(Uri.parse(exeUrl));
                    final res = await req.close();
                    final bytes = await consolidateHttpClientResponseBytes(res);
                    final file = File(path)..writeAsBytesSync(bytes);
                    await Process.start(path, [], mode: ProcessStartMode.detached);
                    exit(0);
                  },
                  child: const Text('Mettre à jour'),
                ),
              ],
            ),
          );
        }
      }
    } catch (_) {
      // Ignorer les erreurs de mise à jour
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('fr_FR', null);

  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString('appTheme');
  if (stored != null) {
    themeNotifier.value = AppTheme.values.firstWhere(
          (e) => e.toString() == stored,
      orElse: () => AppTheme.light,
    );
  }

  // Persister toute modification de thème en local ET en Firestore
  themeNotifier.addListener(() async {
    await prefs.setString('appTheme', themeNotifier.value.toString());
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'theme': themeNotifier.value.toString()}, SetOptions(merge: true));
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PluginProvider()),
        ChangeNotifierProvider(
          create: (_) => DashboardWidgetProvider()
            ..addWidget(const ProjectProgressWidget()),
        ),
        // ← Fournit maintenant UpdateManager à toute l’app
        ChangeNotifierProvider(create: (_) => UpdateManager()),
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
      builder: (context, currentAppTheme, _) {
        final themeData = {
          AppTheme.light: lightTheme,
          AppTheme.dark: darkTheme,
          AppTheme.sequoia: sequoiaTheme,
        }[currentAppTheme]!;

        return MaterialApp(
          title: 'Mon App',
          debugShowCheckedModeBanner: false,
          theme: themeData,
          home: const AuthGate(),
          routes: {
            '/login': (_) => const LoginPage(),
            '/register': (_) => const RegisterPage(),
            '/profile-setup': (_) => const ProfileSetupScreen(),
            '/home': (_) => const HomeScreen(),
          },
        );
      },
    );
  }
}
