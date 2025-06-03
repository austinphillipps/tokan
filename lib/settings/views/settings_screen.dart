import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/views/login_screen.dart';
import '../../main.dart'; // Pour accéder à themeNotifier
import 'profile_screen.dart'; // Import de la page Profil

/// Page Paramètres de l’app
/// Par défaut, on garde le design sombre existant (gris foncé),
/// et on ajoute la possibilité de basculer vers un thème clair.
class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    // On récupère l’état initial du themeNotifier (true si sombre)
    _isDarkMode = (themeNotifier.value == ThemeMode.dark);
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    /// Dans le darkTheme, on voulait :
    ///  • scaffoldBackgroundColor = Colors.grey[900]
    ///  • appBar background = Colors.grey[850]
    ///  • ListTile tileColor = Colors.grey[850], texte blanc, icônes blanches, sous-texte blanc70
    ///
    /// Dans le lightTheme, on choisit par exemple :
    ///  • scaffoldBackgroundColor = Colors.grey[100]
    ///  • appBar background = Colors.white
    ///  • ListTile tileColor = Colors.white, texte noir87, icônes noir87, sous-texte noir54
    ///
    /// Ici, on exploite Theme.of(context) pour récupérer les couleurs dynamiques.

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = _isDarkMode;
    // Couleur de fond de la Scaffold est gérée par ThemeData.scaffoldBackgroundColor
    // Texte principal (titres de section) :
    final sectionTitleColor = isDark
        ? Colors.white70
        : colorScheme.onBackground.withOpacity(0.7);
    // Tile background :
    final tileBgColor = isDark ? Colors.grey[850]! : Colors.white;
    // Texte et icônes dans les ListTile :
    final tileIconColor = isDark ? Colors.white : Colors.black87;
    final tileTextColor = isDark ? Colors.white : Colors.black87;
    // Couleur d’accent (par exemple l’icône du switch) :
    final accentColor = isDark ? Colors.blueAccent : colorScheme.primary;

    return Scaffold(
      backgroundColor:
      isDark ? Colors.grey[900] : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        title: const Text('Paramètres'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ============================
          // SECTION « Général »
          // ============================
          Text(
            'Général',
            style: TextStyle(
              color: sectionTitleColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // ---------------------------------------------------------------
          // SwitchListTile pour basculer Thème sombre / clair
          // ---------------------------------------------------------------
          Container(
            decoration: BoxDecoration(
              color: tileBgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: SwitchListTile(
              title: Text(
                'Thème sombre',
                style: TextStyle(color: tileTextColor),
              ),
              subtitle: Text(
                _isDarkMode ? 'Activé' : 'Désactivé',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              value: _isDarkMode,
              onChanged: (bool newValue) {
                setState(() {
                  _isDarkMode = newValue;
                  themeNotifier.value =
                  newValue ? ThemeMode.dark : ThemeMode.light;
                });
              },
              secondary: Icon(
                _isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                color: accentColor,
              ),
              activeColor: accentColor,
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white24),

          // ============================
          // SECTION « Compte »
          // ============================
          Text(
            'Compte',
            style: TextStyle(
              color: sectionTitleColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          _SettingTile(
            icon: Icons.person,
            label: 'Profil',
            tileBgColor: tileBgColor,
            iconColor: tileIconColor,
            textColor: tileTextColor,
            onTap: () {
              // Navigation vers la page Profil
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),

          _SettingTile(
            icon: Icons.logout,
            label: 'Se déconnecter',
            tileBgColor: tileBgColor,
            iconColor: Colors.redAccent,
            textColor: Colors.redAccent,
            onTap: () => _signOut(context),
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white24),

          // ============================
          // SECTION « À propos »
          // ============================
          Text(
            'À propos',
            style: TextStyle(
              color: sectionTitleColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          _SettingTile(
            icon: Icons.info_outline,
            label: 'Version',
            tileBgColor: tileBgColor,
            iconColor: tileIconColor,
            textColor: tileTextColor,
            trailing: Text(
              '0.1.0',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            onTap: () {
              // Rien à faire pour la version
            },
          ),

          _SettingTile(
            icon: Icons.support_agent,
            label: 'Support',
            tileBgColor: tileBgColor,
            iconColor: tileIconColor,
            textColor: tileTextColor,
            onTap: () {
              // TODO: ouvrir page ou lien de support
            },
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;
  final Color tileBgColor;
  final Color iconColor;
  final Color textColor;

  const _SettingTile({
    Key? key,
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
    required this.tileBgColor,
    required this.iconColor,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: tileBgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(label, style: TextStyle(color: textColor)),
        trailing: trailing ??
            Icon(
              Icons.chevron_right,
              color: iconColor.withOpacity(0.6),
            ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        dense: true,
      ),
    );
  }
}
