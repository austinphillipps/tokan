// lib/shared/interface/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/views/login_screen.dart';
import '../../main.dart'; // Pour AppTheme et themeNotifier
import 'profile_screen.dart'; // Import de la page Profil
import 'widget_settings_screen.dart';

/// Page Paramètres de l’app
/// Ajoute les thèmes Clair / Sombre / Sequoia et persiste le choix.
class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppTheme _selectedTheme;

  @override
  void initState() {
    super.initState();
    // Récupère l’état actuel du themeNotifier
    _selectedTheme = themeNotifier.value;
  }

  /// Sauvegarde et applique le thème sélectionné
  Future<void> _onThemeChanged(AppTheme? newTheme) async {
    if (newTheme == null) return;
    setState(() {
      _selectedTheme = newTheme;
      themeNotifier.value = newTheme;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appTheme', newTheme.toString());
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
    final bool isDarkStyle = _selectedTheme == AppTheme.dark ||
        _selectedTheme == AppTheme.sequoia;
    final colorScheme = Theme.of(context).colorScheme;

    final sectionTitleColor = isDarkStyle
        ? Colors.white70
        : colorScheme.onBackground.withOpacity(0.7);
    final tileBgColor    = isDarkStyle ? Colors.grey[850]! : Colors.white;
    final tileIconColor  = isDarkStyle ? Colors.white : Colors.black87;
    final tileTextColor  = isDarkStyle ? Colors.white : Colors.black87;
    final accentColor    = isDarkStyle ? Colors.blueAccent : colorScheme.primary;

    return Scaffold(
      backgroundColor: isDarkStyle
          ? Colors.grey[900]
          : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDarkStyle ? Colors.grey[850] : Colors.white,
        foregroundColor: isDarkStyle ? Colors.white : Colors.black,
        title: const Text('Paramètres'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SECTION « Général »
          Text(
            'Général',
            style: TextStyle(
              color: sectionTitleColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: tileBgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.palette, color: accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<AppTheme>(
                    isExpanded: true,
                    value: _selectedTheme,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: AppTheme.light,
                        child: Text('Clair'),
                      ),
                      DropdownMenuItem(
                        value: AppTheme.dark,
                        child: Text('Sombre'),
                      ),
                      DropdownMenuItem(
                        value: AppTheme.sequoia,
                        child: Text('Sequoia'),
                      ),
                    ],
                    onChanged: _onThemeChanged,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          _SettingTile(
            icon: Icons.widgets,
            label: 'Widgets du dashboard',
            tileBgColor: tileBgColor,
            iconColor: tileIconColor,
            textColor: tileTextColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const WidgetSettingsScreen()),
              );
            },
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white24),

          // SECTION « Compte »
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

          // SECTION « À propos »
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
                color: isDarkStyle ? Colors.white54 : Colors.black54,
              ),
            ),
            onTap: () {},
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
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        dense: true,
      ),
    );
  }
}
