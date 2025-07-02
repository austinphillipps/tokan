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
import 'features/auth/views/profile_setup_screen.dart';
import 'shared/interface/interface.dart'; // HomeScreen

import 'services/update_manager.dart';    // ← UpdateManager

/// Global navigator key for dialogs and navigation outside widget context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Enum for theme selection
enum AppTheme { light, dark, sequoia }

/// Notifier to switch themes at runtime
final ValueNotifier<AppTheme> themeNotifier = ValueNotifier<AppTheme>(AppTheme.light);

/// Application colors
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

/// 1) Define ColorSchemes
const ColorScheme lightColorScheme = ColorScheme.light(
  primary: AppColors.blue,
  secondary: AppColors.green,
  background: AppColors.lightGreyBackground,
  surface: Colors.white,
  onPrimary: Colors.black,
  onSecondary: Colors.black,
  onBackground: Colors.black,
  onSurface: Colors.black,
);

const ColorScheme darkColorScheme = ColorScheme.dark(
  primary: AppColors.blue,
  secondary: AppColors.green,
  background: AppColors.darkBackground,
  surface: AppColors.darkBackground,
  onPrimary: Colors.white,
  onSecondary: Colors.white,
  onBackground: Colors.white,
  onSurface: Colors.white,
);

/// 2) Light Theme using ColorScheme
final ThemeData lightTheme = ThemeData.from(
  colorScheme: lightColorScheme,
).copyWith(
  scaffoldBackgroundColor: lightColorScheme.background,
  canvasColor: lightColorScheme.surface,
  cardColor: lightColorScheme.surface,
  dialogBackgroundColor: lightColorScheme.surface,
  bottomSheetTheme: BottomSheetThemeData(backgroundColor: lightColorScheme.surface),
  appBarTheme: AppBarTheme(
    backgroundColor: lightColorScheme.primary,
    foregroundColor: lightColorScheme.onPrimary,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: lightColorScheme.primary,
      foregroundColor: lightColorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: lightColorScheme.primary),
  ),
  iconTheme: IconThemeData(color: lightColorScheme.onSurface),
  textTheme: ThemeData.light().textTheme.apply(
    bodyColor: lightColorScheme.onBackground,
    displayColor: lightColorScheme.onBackground,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.all(AppColors.green),
    trackColor: MaterialStateProperty.resolveWith((states) {
      return states.contains(MaterialState.selected)
          ? AppColors.green.withOpacity(0.5)
          : null;
    }),
  ),
  checkboxTheme: CheckboxThemeData(
    checkColor: MaterialStateProperty.all(Colors.white),
    fillColor: MaterialStateProperty.resolveWith((states) {
      return states.contains(MaterialState.selected)
          ? AppColors.green
          : null;
    }),
  ),
);

/// 3) Dark Theme using ColorScheme
final ThemeData darkTheme = ThemeData.from(
  colorScheme: darkColorScheme,
).copyWith(
  scaffoldBackgroundColor: darkColorScheme.background,
  canvasColor: darkColorScheme.surface,
  cardColor: darkColorScheme.surface,
  dialogBackgroundColor: darkColorScheme.surface,
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    selectedIconTheme: IconThemeData(color: darkColorScheme.primary),
    unselectedIconTheme: IconThemeData(color: Colors.grey),
    backgroundColor: darkColorScheme.background,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.darkGreyBackground,
    foregroundColor: darkColorScheme.onPrimary,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: darkColorScheme.primary,
      foregroundColor: darkColorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: darkColorScheme.primary),
  ),
  iconTheme: IconThemeData(color: darkColorScheme.primary),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.all(AppColors.green),
    trackColor: MaterialStateProperty.resolveWith((states) {
      return states.contains(MaterialState.selected)
          ? AppColors.green.withOpacity(0.5)
          : null;
    }),
  ),
  checkboxTheme: CheckboxThemeData(
    checkColor: MaterialStateProperty.all(Colors.white),
    fillColor: MaterialStateProperty.resolveWith((states) {
      return states.contains(MaterialState.selected)
          ? AppColors.green
          : null;
    }),
  ),
);

/// 4) Sequoia Theme (frosted glass)
final ThemeData sequoiaTheme = darkTheme.copyWith(
  scaffoldBackgroundColor: Colors.transparent,
  canvasColor: Colors.black.withOpacity(0.5),
  cardColor: Colors.black.withOpacity(0.5),
  dialogBackgroundColor: Colors.black.withOpacity(0.5),
  bottomSheetTheme: BottomSheetThemeData(backgroundColor: Colors.black.withOpacity(0.5)),
  listTileTheme: ListTileThemeData(
    tileColor: Colors.black54,
    iconColor: Colors.white,
    textColor: Colors.white,
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: Colors.black54,
    textStyle: TextStyle(color: Colors.white),
  ),
  chipTheme: ChipThemeData(
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
  bottomNavigationBarTheme: darkTheme.bottomNavigationBarTheme.copyWith(backgroundColor: Colors.black54),
  navigationRailTheme: darkTheme.navigationRailTheme.copyWith(backgroundColor: Colors.black54),
);

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

  themeNotifier.addListener(() async {
    await prefs.setString('appTheme', themeNotifier.value.toString());
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'theme': themeNotifier.value.toString()},
          SetOptions(merge: true));
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PluginProvider()),
        ChangeNotifierProvider(
          create: (_) => DashboardWidgetProvider()..addWidget(const ProjectProgressWidget()),
        ),
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
          AppTheme.light:  lightTheme,
          AppTheme.dark:   darkTheme,
          AppTheme.sequoia: sequoiaTheme,
        }[currentAppTheme]!;

        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Mon App',
          debugShowCheckedModeBanner: false,
          theme: themeData,
          builder: (context, child) {
            return Stack(
              children: [
                if (child != null) child,
                Consumer<UpdateManager>(
                  builder: (context, updateMgr, _) {
                    if (updateMgr.status == UpdateStatus.downloading) {
                      return Positioned(
                        bottom: 16,
                        right: 16,
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, value: updateMgr.progress),
                                ),
                                const SizedBox(width: 8),
                                const Text('Mise à jour en cours…'),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            );
          },
          home: const AuthGate(),
          routes: {
            '/login':         (_) => const LoginPage(),
            '/register':      (_) => const RegisterPage(),
            '/profile-setup': (_) => const ProfileSetupScreen(),
            '/home':          (_) => const HomeScreen(),
          },
        );
      },
    );
  }
}
