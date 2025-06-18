import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../shared/interface/interface.dart';
import 'views/explore_schedule_page.dart';
import '../../utils/tab_launcher.dart';

class OnboardingFlow extends StatefulWidget {
  final User user;
  const OnboardingFlow({Key? key, required this.user}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _dialCode = '+33';
  final _companyCtrl = TextEditingController();

  final PageController _pageController = PageController();
  int _currentStep = 0;

  String? _selectedCompany;
  String? _selectedColor;

  final List<String> _sampleCompanies = [
    'TechCorp',
    'MediHealth',
    'EcoWorld',
    'AgriFoods',
    'SmartHome'
  ];

  final List<String> _colors = [
    'blue',
    'green',
    'orange',
    'purple'
  ];

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _companyCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .update({
      'firstName': _firstNameCtrl.text.trim(),
      'lastName': _lastNameCtrl.text.trim(),
      'username':  _usernameCtrl.text.trim(),
      'phone': '$_dialCode ${_phoneCtrl.text.trim()}',
      'company': _selectedCompany ?? _companyCtrl.text.trim(),
      'themeColor': _selectedColor,
    });
    if (mounted) {
      // Ouvre la page d'options dans un nouvel onglet sur le Web
      openTab('/#/explore-schedule');
      // Redirige l'utilisateur vers l'écran d'accueil dans l'onglet actuel
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenue'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Container(
                margin: const EdgeInsets.all(4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentStep == index
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStep,
                child: Text(_currentStep < 2 ? 'Suivant' : 'Terminer'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _firstNameCtrl,
              decoration: const InputDecoration(labelText: 'Prénom'),
              validator: (v) => v == null || v.isEmpty ? 'Entrez votre prénom' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastNameCtrl,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: (v) => v == null || v.isEmpty ? 'Entrez votre nom' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(labelText: 'Nom d\'utilisateur'),
              validator: (v) => v == null || v.isEmpty ? 'Choisissez un pseudo' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                DropdownButton<String>(
                  value: _dialCode,
                  items: const [
                    DropdownMenuItem(value: '+33', child: Text('+33')),
                    DropdownMenuItem(value: '+32', child: Text('+32')),
                    DropdownMenuItem(value: '+1', child: Text('+1')),
                  ],
                  onChanged: (v) => setState(() => _dialCode = v ?? '+33'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Téléphone'),
                    validator: (v) => v == null || v.isEmpty ? 'Entrez votre téléphone' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _companyCtrl,
              decoration: const InputDecoration(labelText: 'Société'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recherche de votre entreprise en France'),
          const SizedBox(height: 12),
          TextField(
            controller: _companyCtrl,
            decoration: const InputDecoration(labelText: 'Nom de l\'entreprise'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: _sampleCompanies
                  .where((c) => c
                      .toLowerCase()
                      .contains(_companyCtrl.text.toLowerCase()))
                  .map((c) => ListTile(
                        title: Text(c),
                        trailing: _selectedCompany == c
                            ? const Icon(Icons.check)
                            : null,
                        onTap: () => setState(() => _selectedCompany = c),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choisissez une couleur pour l\'interface'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: _colors.map((c) {
              final color = _colorFromName(c);
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: _selectedColor == c
                        ? Border.all(color: Colors.black, width: 3)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _colorFromName(String name) {
    switch (name) {
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
}
