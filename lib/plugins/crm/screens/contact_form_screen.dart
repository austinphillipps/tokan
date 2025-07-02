// lib/plugins/crm/screens/contact_form_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tokan/main.dart'; // pour AppColors
import 'package:tokan/plugins/crm/models/contact.dart';
import 'package:tokan/plugins/crm/providers/contact_provider.dart';
import 'package:tokan/plugins/crm/data/country_codes.dart';

class ContactFormScreen extends StatefulWidget {
  /// Si contactId est null → création, sinon édition
  final String? contactId;
  final VoidCallback? onSaved;
  const ContactFormScreen({Key? key, this.contactId, this.onSaved})
      : super(key: key);

  @override
  State<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _dialCode = '+33';
  bool _loading = false;

  bool get _isEditing => widget.contactId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    final contact = await context.read<ContactProvider>().fetchById(widget.contactId!);
    if (contact != null) {
      _firstNameCtrl.text = contact.firstName;
      _nameCtrl.text  = contact.name;
      _emailCtrl.text = contact.email;
      if (contact.phone != null && contact.phone!.isNotEmpty) {
        final parts = contact.phone!.split(' ');
        if (parts.length > 1) {
          _dialCode = parts.first;
          _phoneCtrl.text = parts.sublist(1).join(' ');
        } else {
          _phoneCtrl.text = contact.phone!;
        }
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final provider = context.read<ContactProvider>();
    final contact = Contact(
      id:    widget.contactId,
      firstName: _firstNameCtrl.text.trim(),
      name:  _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty
          ? null
          : '$_dialCode ${_phoneCtrl.text.trim()}',
    );

    if (_isEditing) {
      await provider.update(contact);
    } else {
      await provider.create(contact);
    }

    setState(() => _loading = false);
    if (widget.onSaved != null) {
      widget.onSaved!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Modifier le contact' : 'Nouveau contact';

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: AppColors.glassHeader,
        elevation: 0,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SafeArea(
        child: Container(
          color: AppColors.glassBackground,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _firstNameCtrl,
                  decoration: const InputDecoration(labelText: 'Prénom'),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Le prénom est requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Le nom est requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Email invalide' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _dialCode,
                        decoration: const InputDecoration(labelText: 'Indicatif'),
                        items: [
                          for (final c in countryCodes)
                            DropdownMenuItem(
                              value: c.dialCode,
                              child: Text('${c.name} (${c.dialCode})'),
                            ),
                        ],
                        onChanged: (val) => setState(() => _dialCode = val ?? '+33'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(labelText: 'Téléphone'),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton(
            onPressed: _loading ? null : _onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _loading
                ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(color: Colors.white),
            )
                : Text(title),
          ),
        ),
      ),
    );
  }
}