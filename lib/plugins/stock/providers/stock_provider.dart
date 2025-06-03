import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../models/inventory_count.dart';
import '../services/stock_service.dart';

class StockProvider extends ChangeNotifier {
  final StockService _service = StockService();

  final List<Product> _products = [];
  final List<InventoryCount> _inventoryCounts = [];

  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<Product> get products => List.unmodifiable(_products);
  List<InventoryCount> get inventoryCounts => List.unmodifiable(_inventoryCounts);

  /// Compte des produits dont la quantité est ≤ reorderThreshold (et > minimumStock)
  int get lowStockCount => _products
      .where((p) =>
  p.quantityInStock <= p.reorderThreshold &&
      p.quantityInStock > p.minimumStock)
      .length;

  /// Compte des produits en rupture (quantityInStock == 0)
  int get outOfStockCount =>
      _products.where((p) => p.quantityInStock == 0).length;

  /// Quantité totale de tous les produits
  int get totalItems =>
      _products.fold(0, (sum, p) => sum + p.quantityInStock);

  /// Charge tous les produits depuis Firestore
  Future<void> fetchAllProducts() async {
    _isLoading = true;
    notifyListeners();

    final fetched = await _service.fetchAllProducts();
    _products
      ..clear()
      ..addAll(fetched);

    _isLoading = false;
    notifyListeners();
  }

  /// Ajoute un produit
  Future<void> addProduct(Product product) async {
    await _service.addProduct(product);
    _products.add(product);
    notifyListeners();
  }

  /// Met à jour un produit
  Future<void> updateProduct(Product product) async {
    await _service.updateProduct(product);
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _products[idx] = product;
      notifyListeners();
    }
  }

  /// Supprime un produit
  Future<void> deleteProduct(String id) async {
    await _service.deleteProduct(id);
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  /// Enregistre un mouvement de stock
  Future<void> addStockMovement(StockMovement movement) async {
    await _service.addStockMovement(movement);
    await fetchAllProducts();
  }

  /// Enregistre un inventaire et applique les ajustements nécessaires
  Future<void> addInventoryCount(InventoryCount count) async {
    await _service.addInventoryCount(count);
    await fetchAllProducts();
    await fetchAllInventoryCounts();
  }

  /// Charge tous les inventaires physiques
  Future<void> fetchAllInventoryCounts() async {
    final fetched = await _service.fetchAllInventoryCounts();
    _inventoryCounts
      ..clear()
      ..addAll(fetched);
    notifyListeners();
  }

  /// Retourne les produits à alerter (stock ≤ seuil)
  Future<List<Product>> checkReorderAlerts() async {
    return await _service.checkReorderAlerts();
  }

  /// Recalcule la valeur totale du stock
  Future<double> recalcStockValue() async {
    return await _service.recalcStockValue();
  }

  /// Crée un ajustement ponctuel pour un produit
  Future<void> generateInventoryAdjustment({
    required String productId,
    required int countedQuantity,
    required String performedBy,
  }) async {
    await _service.generateInventoryAdjustment(
      productId: productId,
      countedQuantity: countedQuantity,
      performedBy: performedBy,
    );
    await fetchAllProducts();
  }
}
