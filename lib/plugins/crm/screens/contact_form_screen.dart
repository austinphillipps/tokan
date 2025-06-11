// lib/plugins/crm/screens/contact_form_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tokan/main.dart'; // pour AppColors
import 'package:tokan/plugins/crm/models/contact.dart';
import 'package:tokan/plugins/crm/providers/contact_provider.dart';

class ContactFormScreen extends StatefulWidget {
  /// Si contactId est null → création, sinon édition
  final String? contactId;
  final VoidCallback? onClose;
  const ContactFormScreen({Key? key, this.contactId, this.onClose}) : super(key: key);

  @override
  State<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _phonePrefix = '+33';
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
      _nameCtrl.text  = contact.name;
      _firstNameCtrl.text = contact.firstName;
      _emailCtrl.text = contact.email;
      _phonePrefix = contact.phonePrefix;
      _phoneCtrl.text = contact.phone ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final provider = context.read<ContactProvider>();
    final contact = Contact(
      id:    widget.contactId,
      name:  _nameCtrl.text.trim(),
      firstName: _firstNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phonePrefix: _phonePrefix,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );

    if (_isEditing) {
      await provider.update(contact);
    } else {
      await provider.create(contact);
    }

    setState(() => _loading = false);
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _firstNameCtrl.dispose();
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
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Le nom est requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firstNameCtrl,
                  decoration: const InputDecoration(labelText: 'Prénom'),
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
                    DropdownButton<String>(
                      value: _phonePrefix,
                      onChanged: (v) => setState(() => _phonePrefix = v ?? _phonePrefix),
                      items: const ['+33', '+596', '+590']
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
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
