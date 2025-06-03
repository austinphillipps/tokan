// lib/features/stock/screens/stock_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/product.dart';
import '../providers/stock_provider.dart';
import '../utils/csv_utils.dart';

import 'stock_movement_dialog.dart';
import 'movement_history_screen.dart';
import 'inventory_count_screen.dart';
import 'inventory_history_screen.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({Key? key}) : super(key: key);

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().fetchAllProducts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _exportCsv(List<Product> products) async {
    final csv = CsvUtils.generateProductCsv(products);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/export_produits.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Export Stock CSV');
  }

  Future<void> _importCsv() async {
    final importedProducts = await CsvUtils.pickAndParseProductCsv();
    if (importedProducts.isEmpty) return;

    final provider = context.read<StockProvider>();
    for (final p in importedProducts) {
      await provider.addProduct(p);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${importedProducts.length} produits importés')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color primaryColor = theme.colorScheme.primary;
    final Color onPrimary = theme.colorScheme.onPrimary;
    final Color backgroundColor = theme.scaffoldBackgroundColor;
    final Color onBackground = theme.colorScheme.onBackground;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text('Gestion de stock', style: TextStyle(color: onPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2),
            tooltip: 'Nouvel inventaire',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InventoryCountScreen()),
              );
            },
            color: theme.iconTheme.color,
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Historique inventaires',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InventoryHistoryScreen()),
              );
            },
            color: theme.iconTheme.color,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Importer CSV',
            onPressed: _importCsv,
            color: theme.iconTheme.color,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Exporter CSV',
            onPressed: () {
              final products = context.read<StockProvider>().products;
              _exportCsv(products);
            },
            color: theme.iconTheme.color,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            color: primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(color: onPrimary),
                    cursorColor: onPrimary,
                    decoration: InputDecoration(
                      hintText: 'Rechercher produit...',
                      hintStyle: TextStyle(color: onPrimary.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.search, color: onPrimary),
                      filled: true,
                      fillColor: theme.brightness == Brightness.dark
                          ? Colors.white10
                          : Colors.grey[100],
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.filter_list, color: onPrimary),
                  tooltip: 'Filtres avancés',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: theme.dialogBackgroundColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (_) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Filtres avancés stock',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: onBackground)),
                            const SizedBox(height: 12),
                            Text('Fonctionnalité en cours de développement…',
                                style: TextStyle(color: onBackground)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // DataTable des produits
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: theme.cardColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                clipBehavior: Clip.antiAlias,
                child: Consumer<StockProvider>(
                  builder: (context, stockProv, _) {
                    if (stockProv.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allProducts = stockProv.products;
                    if (allProducts.isEmpty) {
                      return Center(
                        child: Text(
                          "Aucun produit trouvé",
                          style: TextStyle(color: onBackground),
                        ),
                      );
                    }

                    final query = _searchCtrl.text.trim().toLowerCase();
                    final filtered = allProducts.where((prod) {
                      final name = prod.name.toLowerCase();
                      final sku = prod.sku.toLowerCase();
                      return name.contains(query) || sku.contains(query);
                    }).toList();

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor:
                        MaterialStateProperty.all(primaryColor.withOpacity(0.1)),
                        dataRowColor: MaterialStateProperty.resolveWith((states) =>
                        theme.brightness == Brightness.dark
                            ? Colors.white10
                            : Colors.grey[50]),
                        headingTextStyle: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        columns: const [
                          DataColumn(label: Text('Produit')),
                          DataColumn(label: Text('Réf.')),
                          DataColumn(label: Text('Qte en stock')),
                          DataColumn(label: Text('Seuil alerte')),
                          DataColumn(label: Text('Dernière MAJ')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: filtered.map((prod) {
                          Color? rowColor;
                          if (prod.quantityInStock == 0) {
                            rowColor = Colors.red.shade50;
                          } else if (prod.quantityInStock <= prod.reorderThreshold) {
                            rowColor = Colors.orange.shade50;
                          }

                          return DataRow(
                            color: MaterialStateProperty.all(rowColor),
                            cells: [
                              DataCell(Text(prod.name,
                                  style: TextStyle(color: onBackground))),
                              DataCell(Text(prod.sku,
                                  style: TextStyle(color: onBackground))),
                              DataCell(Text(prod.quantityInStock.toString(),
                                  style: TextStyle(color: onBackground))),
                              DataCell(Text(prod.reorderThreshold.toString(),
                                  style: TextStyle(color: onBackground))),
                              DataCell(Text(
                                prod.dateUpdated != null
                                    ? '${prod.dateUpdated!.day}/${prod.dateUpdated!.month}/${prod.dateUpdated!.year}'
                                    : '-',
                                style: TextStyle(color: onBackground),
                              )),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.swap_vert, size: 20),
                                    tooltip: 'Mouvement',
                                    color: primaryColor,
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) =>
                                            StockMovementDialog(product: prod),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.history, size: 20),
                                    tooltip: 'Historique',
                                    color: primaryColor,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              MovementHistoryScreen(product: prod),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    tooltip: 'Modifier',
                                    color: primaryColor,
                                    onPressed: () {
                                      _showAddProductDialog(context,
                                          existingProduct: prod);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    tooltip: 'Supprimer',
                                    color: Colors.redAccent,
                                    onPressed: () {
                                      context
                                          .read<StockProvider>()
                                          .deleteProduct(prod.id);
                                    },
                                  ),
                                ],
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddProductDialog(context);
        },
        backgroundColor: primaryColor,
        tooltip: 'Ajouter un produit',
        child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, {Product? existingProduct}) {
    final theme = Theme.of(context);
    final Color primaryColor = theme.colorScheme.primary;

    final _skuCtrl = TextEditingController(text: existingProduct?.sku ?? '');
    final _barcodeCtrl = TextEditingController(text: existingProduct?.barcode ?? '');
    final _nameCtrl = TextEditingController(text: existingProduct?.name ?? '');
    final _descCtrl = TextEditingController(text: existingProduct?.description ?? '');
    final _categoryCtrl = TextEditingController(text: existingProduct?.categoryId ?? '');
    final _supplierCtrl = TextEditingController(text: existingProduct?.supplierId ?? '');
    final _unitPriceCtrl = TextEditingController(
        text: existingProduct != null ? existingProduct.unitPrice.toString() : '');
    final _costPriceCtrl = TextEditingController(
        text: existingProduct != null ? existingProduct.costPrice.toString() : '');
    final _unitOfMeasureCtrl =
    TextEditingController(text: existingProduct?.unitOfMeasure ?? '');
    final _imageUrlCtrl = TextEditingController(text: existingProduct?.imageUrl ?? '');
    final _quantityCtrl = TextEditingController(
        text: existingProduct != null ? existingProduct.quantityInStock.toString() : '');
    final _reorderThresholdCtrl = TextEditingController(
        text: existingProduct != null ? existingProduct.reorderThreshold.toString() : '');
    final _reorderQuantityCtrl = TextEditingController(
        text: existingProduct != null ? existingProduct.reorderQuantity.toString() : '');
    final _minimumStockCtrl = TextEditingController(
        text: existingProduct != null ? existingProduct.minimumStock.toString() : '');
    final _maximumStockCtrl = TextEditingController(
        text: existingProduct != null ? existingProduct.maximumStock.toString() : '');
    DateTime? _expiryDate = existingProduct?.expiryDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: theme.dialogBackgroundColor,
              title: Text(
                existingProduct == null ? 'Ajouter un produit' : 'Modifier le produit',
                style: TextStyle(color: theme.colorScheme.onBackground),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: _skuCtrl, decoration: const InputDecoration(labelText: 'SKU')),
                    TextField(controller: _barcodeCtrl, decoration: const InputDecoration(labelText: 'Code-barres')),
                    TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nom du produit')),
                    TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                    TextField(controller: _categoryCtrl, decoration: const InputDecoration(labelText: 'ID Catégorie')),
                    TextField(controller: _supplierCtrl, decoration: const InputDecoration(labelText: 'ID Fournisseur')),
                    TextField(
                      controller: _unitPriceCtrl,
                      decoration: const InputDecoration(labelText: 'Prix unitaire'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    TextField(
                      controller: _costPriceCtrl,
                      decoration: const InputDecoration(labelText: 'Coût d\'achat'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    TextField(controller: _unitOfMeasureCtrl, decoration: const InputDecoration(labelText: 'Unité de mesure')),
                    TextField(controller: _imageUrlCtrl, decoration: const InputDecoration(labelText: 'URL de l\'image')),
                    TextField(
                      controller: _quantityCtrl,
                      decoration: const InputDecoration(labelText: 'Quantité en stock'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _reorderThresholdCtrl,
                      decoration: const InputDecoration(labelText: 'Seuil de réapprovisionnement'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _reorderQuantityCtrl,
                      decoration: const InputDecoration(labelText: 'Quantité suggérée à commander'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _minimumStockCtrl,
                      decoration: const InputDecoration(labelText: 'Stock minimum'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _maximumStockCtrl,
                      decoration: const InputDecoration(labelText: 'Stock maximum'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Date péremption: '),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _expiryDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              builder: (ctx, child) {
                                final pickerTheme = theme.brightness == Brightness.dark
                                    ? theme.copyWith(
                                  colorScheme: ColorScheme.dark(
                                    primary: primaryColor,
                                    onPrimary: theme.colorScheme.onPrimary,
                                    onSurface: theme.colorScheme.onBackground,
                                  ),
                                  dialogBackgroundColor: theme.dialogBackgroundColor,
                                )
                                    : theme.copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: primaryColor,
                                    onPrimary: theme.colorScheme.onPrimary,
                                    onSurface: theme.colorScheme.onBackground,
                                  ),
                                );
                                return Theme(data: pickerTheme, child: child!);
                              },
                            );
                            if (picked != null) {
                              setState(() => _expiryDate = picked);
                            }
                          },
                          child: Text(
                            _expiryDate == null
                                ? 'Choisir'
                                : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                            style: TextStyle(color: primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.secondary),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final now = DateTime.now();
                    final id = existingProduct?.id ?? const Uuid().v4();

                    final product = Product(
                      id: id,
                      sku: _skuCtrl.text.trim(),
                      barcode: _barcodeCtrl.text.trim(),
                      name: _nameCtrl.text.trim(),
                      description: _descCtrl.text.trim(),
                      categoryId: _categoryCtrl.text.trim(),
                      supplierId: _supplierCtrl.text.trim(),
                      unitPrice: double.tryParse(_unitPriceCtrl.text) ?? 0.0,
                      costPrice: double.tryParse(_costPriceCtrl.text) ?? 0.0,
                      unitOfMeasure: _unitOfMeasureCtrl.text.trim(),
                      imageUrl: _imageUrlCtrl.text.trim(),
                      quantityInStock: int.tryParse(_quantityCtrl.text) ?? 0,
                      reorderThreshold: int.tryParse(_reorderThresholdCtrl.text) ?? 0,
                      reorderQuantity: int.tryParse(_reorderQuantityCtrl.text) ?? 0,
                      minimumStock: int.tryParse(_minimumStockCtrl.text) ?? 0,
                      maximumStock: int.tryParse(_maximumStockCtrl.text) ?? 0,
                      dateCreated: existingProduct?.dateCreated ?? now,
                      dateUpdated: now,
                      expiryDate: _expiryDate,
                    );

                    if (existingProduct == null) {
                      context.read<StockProvider>().addProduct(product);
                    } else {
                      context.read<StockProvider>().updateProduct(product);
                    }

                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  child: Text(
                    existingProduct == null ? 'Ajouter' : 'Enregistrer',
                    style: TextStyle(color: theme.colorScheme.onPrimary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
