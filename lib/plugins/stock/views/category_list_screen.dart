// lib/plugins/stock/views/category_list_screen.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../services/stock_service.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({Key? key}) : super(key: key);

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final StockService _service = StockService();
  bool _isLoading = false;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() => _isLoading = true);
      final fetched = await _service.fetchAllCategories();
      fetched.sort((a, b) => a.name.compareTo(b.name));
      setState(() {
        _categories = fetched;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement : $e')),
      );
    }
  }

  Future<void> _showCategoryDialog({Category? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final parentCtrl = TextEditingController(text: existing?.parentId ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');

    final isNew = existing == null;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isNew ? 'Nouvelle catégorie' : 'Modifier la catégorie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            TextField(
              controller: parentCtrl,
              decoration: const InputDecoration(labelText: 'ID parent (optionnel)'),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              try {
                if (isNew) {
                  final newCategory = Category(
                    id: const Uuid().v4(),
                    name: name,
                    parentId: parentCtrl.text.trim().isEmpty
                        ? null
                        : parentCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                  );
                  await _service.addCategory(newCategory);
                } else {
                  existing!.name = name;
                  existing.parentId = parentCtrl.text.trim().isEmpty
                      ? null
                      : parentCtrl.text.trim();
                  existing.description = descCtrl.text.trim();
                  await _service.updateCategory(existing);
                }

                if (context.mounted) Navigator.pop(context);
                _loadCategories();
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur : $e')),
                  );
                }
              }
            },
            child: Text(isNew ? 'Ajouter' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer suppression'),
        content: Text('Supprimer la catégorie "${category.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteCategory(category.id);
        _loadCategories();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catégories')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? const Center(child: Text('Aucune catégorie enregistrée.'))
          : ListView.separated(
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return ListTile(
            title: Text(cat.name),
            subtitle: Text(
              cat.parentId == null
                  ? 'Niveau racine'
                  : 'Parent : ${cat.parentId}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showCategoryDialog(existing: cat),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDeleteCategory(cat),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        tooltip: 'Ajouter une catégorie',
        child: const Icon(Icons.add),
      ),
    );
  }
}
