// lib/features/auth/views/profile_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import '../services/auth_service.dart';
import '../../../shared/interface/interface.dart'; // pour HomeScreen
import '../../../main.dart'; // pour themeNotifier et AppTheme

/// Formatteur pour forcer tout le texte en majuscules
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text.toUpperCase();
    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Formatteur pour mettre la première lettre en majuscule et le reste en minuscule
class FirstLetterUpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    final formatted = text[0].toUpperCase() + text.substring(1).toLowerCase();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Écran d'onboarding pour compléter le profil utilisateur.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupStateConstants {
  static const transitionDuration = Duration(milliseconds: 300);
  static const fieldWidth = 300.0;
  static const borderRadius = 50.0;
  static const totalSteps = 4;
  static const themeOptions = ['Clair', 'Sombre', 'Séquoia'];
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  int _step = 0;

  final _lastNameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();

  String _selectedCountryCode = '+1';
  final _phonePart1 = TextEditingController();
  final _phonePart2 = TextEditingController();
  final _phonePart3 = TextEditingController();

  String? _selectedTheme;

  final _focus1 = FocusNode();
  final _focus2 = FocusNode();
  final _focus3 = FocusNode();

  @override
  void dispose() {
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _usernameCtrl.dispose();
    _phonePart1.dispose();
    _phonePart2.dispose();
    _phonePart3.dispose();
    _focus1.dispose();
    _focus2.dispose();
    _focus3.dispose();
    super.dispose();
  }

  OutlineInputBorder _roundedBorder() => OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.black),
    borderRadius:
    BorderRadius.circular(_ProfileSetupStateConstants.borderRadius),
  );

  ButtonStyle _buttonStyle(bool enabled) => ButtonStyle(
    padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 40, vertical: 16)),
    shape: MaterialStateProperty.all(RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
          _ProfileSetupStateConstants.borderRadius),
    )),
    backgroundColor:
    MaterialStateProperty.all(enabled ? Colors.black : Colors.black12),
    foregroundColor:
    MaterialStateProperty.all(enabled ? Colors.white : Colors.black38),
  );

  void _goToStep(int i) => setState(() => _step = i);

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (_step) {
      case 0:
        content = _buildNameStep();
        break;
      case 1:
        content = _buildUsernameStep();
        break;
      case 2:
        content = _buildPhoneStep();
        break;
      case 3:
        content = _buildThemeStep();
        break;
      default:
        content = _buildNameStep();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: _step > 0
            ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => _goToStep(_step - 1),
        )
            : null,
      ),
      body: AnimatedSwitcher(
        duration: _ProfileSetupStateConstants.transitionDuration,
        child: content,
      ),
    );
  }

  Widget _buildDotsIndicator() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      _ProfileSetupStateConstants.totalSteps,
          (i) {
        final isActive = i == _step;
        return GestureDetector(
          onTap: () => _goToStep(i),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
            width: isActive ? 12 : 8,
            height: isActive ? 12 : 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.black : Colors.black26,
            ),
          ),
        );
      },
    ),
  );

  Widget _buildNameStep() {
    final enabled =
        _lastNameCtrl.text.isNotEmpty && _firstNameCtrl.text.isNotEmpty;
    return _stepContainer(
      title: 'Veuillez renseigner votre nom et prénom',
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: _ProfileSetupStateConstants.fieldWidth,
          child: TextField(
            controller: _lastNameCtrl,
            inputFormatters: [UpperCaseTextFormatter()],
            decoration: InputDecoration(
              labelText: 'Nom',
              enabledBorder: _roundedBorder(),
              focusedBorder: _roundedBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: _ProfileSetupStateConstants.fieldWidth,
          child: TextField(
            controller: _firstNameCtrl,
            inputFormatters: [FirstLetterUpperCaseFormatter()],
            decoration: InputDecoration(
              labelText: 'Prénom',
              enabledBorder: _roundedBorder(),
              focusedBorder: _roundedBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 32),
        TextButton(
          onPressed: enabled ? () => _goToStep(1) : null,
          style: _buttonStyle(enabled),
          child: const Text('Suivant'),
        ),
      ]),
    );
  }

  Widget _buildUsernameStep() {
    final enabled = _usernameCtrl.text.isNotEmpty;
    return _stepContainer(
      title: 'Choisissez un nom d\'utilisateur',
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: _ProfileSetupStateConstants.fieldWidth,
          child: TextField(
            controller: _usernameCtrl,
            decoration: InputDecoration(
              labelText: 'Nom d\'utilisateur',
              enabledBorder: _roundedBorder(),
              focusedBorder: _roundedBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 32),
        TextButton(
          onPressed: enabled ? () => _goToStep(2) : null,
          style: _buttonStyle(enabled),
          child: const Text('Suivant'),
        ),
      ]),
    );
  }

  Widget _buildPhoneStep() {
    final enabled = _phonePart1.text.length == 3 &&
        _phonePart2.text.length == 3 &&
        _phonePart3.text.length == 3;
    return _stepContainer(
      title: 'Nous aurons également besoin de votre numéro de téléphone',
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          InkWell(
            onTap: () => showCountryPicker(
              context: context,
              showPhoneCode: true,
              onSelect: (c) =>
                  setState(() => _selectedCountryCode = '+${c.phoneCode}'),
            ),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(
                    _ProfileSetupStateConstants.borderRadius),
              ),
              child: Text(_selectedCountryCode,
                  style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          ...List.generate(3, (i) {
            final ctrl =
            i == 0 ? _phonePart1 : (i == 1 ? _phonePart2 : _phonePart3);
            final focus = i == 0 ? _focus1 : (i == 1 ? _focus2 : _focus3);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                width: 60,
                child: TextField(
                  controller: ctrl,
                  focusNode: focus,
                  maxLength: 3,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    counterText: '',
                    enabledBorder: _roundedBorder(),
                    focusedBorder: _roundedBorder(),
                  ),
                  onChanged: (text) {
                    if (text.length == 3 && i < 2) {
                      FocusScope.of(context)
                          .requestFocus(i == 0 ? _focus2 : _focus3);
                    } else if (text.isEmpty && i > 0) {
                      FocusScope.of(context)
                          .requestFocus(i == 1 ? _focus1 : _focus2);
                    }
                    setState(() {});
                  },
                ),
              ),
            );
          }),
        ]),
        const SizedBox(height: 32),
        TextButton(
          onPressed: enabled ? () => _goToStep(3) : null,
          style: _buttonStyle(enabled),
          child: const Text('Suivant'),
        ),
      ]),
    );
  }

  Widget _buildThemeStep() {
    final enabled = _selectedTheme != null;
    return _stepContainer(
      title: 'Définissez le thème de votre interface',
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _ProfileSetupStateConstants.themeOptions.map((theme) {
            final isActive = theme == _selectedTheme;
            return GestureDetector(
              onTap: () => setState(() => _selectedTheme = theme),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(
                      _ProfileSetupStateConstants.borderRadius / 2),
                  border: Border.all(color: Colors.black),
                ),
                child: Text(
                  theme,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: enabled
              ? () async {
            // Sauvegarde en base
            await AuthService.instance.saveUserProfile(
              lastName: _lastNameCtrl.text,
              firstName: _firstNameCtrl.text,
              username: _usernameCtrl.text,
              phone:
              '$_selectedCountryCode${_phonePart1.text}${_phonePart2.text}${_phonePart3.text}',
              theme: _selectedTheme!,
            );

            // Appliquer immédiatement le thème choisi
            switch (_selectedTheme) {
              case 'Clair':
                themeNotifier.value = AppTheme.light;
                break;
              case 'Sombre':
                themeNotifier.value = AppTheme.dark;
                break;
              case 'Séquoia':
                themeNotifier.value = AppTheme.sequoia;
                break;
            }

            // Redirection vers HomeScreen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
              : null,
          style: _buttonStyle(enabled),
          child: const Text('Terminer'),
        ),
      ]),
    );
  }

  /// Wrapper commun pour chaque étape
  Widget _stepContainer({required String title, required Widget child}) {
    return Align(
      alignment: const Alignment(0, -0.1),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          _buildDotsIndicator(),
          const SizedBox(height: 16),
          child,
        ]),
      ),
    );
  }
}
