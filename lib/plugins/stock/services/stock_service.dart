import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/supplier.dart';
import '../models/stock_movement.dart';
import '../models/location.dart';
import '../models/inventory_count.dart';
import '../models/purchase_order.dart';
import '../models/settings.dart';
import '../models/user_role.dart';

class StockService {
  final FirebaseFirestore _firestore;

  static const String _productsCol = 'products';
  static const String _categoriesCol = 'categories';
  static const String _suppliersCol = 'suppliers';
  static const String _stockMovementsCol = 'stock_movements';
  static const String _locationsCol = 'locations';
  static const String _inventoryCountsCol = 'inventory_counts';
  static const String _purchaseOrdersCol = 'purchase_orders';
  static const String _settingsCol = 'stock_settings';
  static const String _userPermissionsCol = 'user_permissions';

  StockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ─────────── PRODUITS ───────────

  Future<List<Product>> fetchAllProducts() async {
    final snapshot = await _firestore.collection(_productsCol).get();
    return snapshot.docs.map((doc) => Product.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> addProduct(Product product) async {
    final ref = _firestore.collection(_productsCol).doc(product.id);
    await ref.set(product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    final ref = _firestore.collection(_productsCol).doc(product.id);
    await ref.update(product.toMap());
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection(_productsCol).doc(productId).delete();
  }

  // ─────────── CATÉGORIES ───────────

  Future<List<Category>> fetchAllCategories() async {
    final snapshot = await _firestore.collection(_categoriesCol).get();
    return snapshot.docs.map((doc) => Category.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> addCategory(Category category) async {
    await _firestore.collection(_categoriesCol).doc(category.id).set(category.toMap());
  }

  Future<void> updateCategory(Category category) async {
    await _firestore.collection(_categoriesCol).doc(category.id).update(category.toMap());
  }

  Future<void> deleteCategory(String categoryId) async {
    await _firestore.collection(_categoriesCol).doc(categoryId).delete();
  }

  // ─────────── FOURNISSEURS ───────────

  Future<List<Supplier>> fetchAllSuppliers() async {
    final snapshot = await _firestore.collection(_suppliersCol).get();
    return snapshot.docs.map((doc) => Supplier.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> addSupplier(Supplier supplier) async {
    await _firestore.collection(_suppliersCol).doc(supplier.id).set(supplier.toMap());
  }

  Future<void> updateSupplier(Supplier supplier) async {
    await _firestore.collection(_suppliersCol).doc(supplier.id).update(supplier.toMap());
  }

  Future<void> deleteSupplier(String supplierId) async {
    await _firestore.collection(_suppliersCol).doc(supplierId).delete();
  }

  // ─────────── MOUVEMENTS DE STOCK ───────────

  Future<List<StockMovement>> fetchAllMovements() async {
    final snapshot = await _firestore.collection(_stockMovementsCol).get();
    return snapshot.docs.map((doc) => StockMovement.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> addStockMovement(StockMovement movement) async {
    final ref = _firestore.collection(_stockMovementsCol).doc(movement.id);
    await ref.set(movement.toMap());

    final prodRef = _firestore.collection(_productsCol).doc(movement.productId);
    final prodSnap = await prodRef.get();
    if (prodSnap.exists) {
      final prod = Product.fromMap(prodSnap.id, prodSnap.data()!);
      final int currentQty = prod.quantityInStock;

      int change = 0;
      switch (movement.type) {
        case StockMovementType.IN:
          change = movement.quantity;
          break;
        case StockMovementType.OUT:
          change = -movement.quantity;
          break;
        case StockMovementType.ADJUSTMENT:
          change = 0; // L’ajustement ne modifie pas ici directement
          break;
        case StockMovementType.TRANSFER:
          break;
      }

      final newQty = currentQty + change;
      if (change != 0) {
        await prodRef.update({
          'quantityInStock': newQty,
          'dateUpdated': Timestamp.now(),
        });
      }
    }
  }

  Future<void> deleteStockMovement(String movementId) async {
    await _firestore.collection(_stockMovementsCol).doc(movementId).delete();
  }

  // ─────────── INVENTAIRES PHYSIQUES ───────────

  Future<List<InventoryCount>> fetchAllInventoryCounts() async {
    final snapshot = await _firestore.collection(_inventoryCountsCol).get();
    return snapshot.docs.map((doc) => InventoryCount.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> addInventoryCount(InventoryCount count) async {
    final ref = _firestore.collection(_inventoryCountsCol).doc(count.id);
    await ref.set(count.toMap());

    for (final line in count.lines) {
      final prodRef = _firestore.collection(_productsCol).doc(line.productId);
      final prodSnap = await prodRef.get();

      if (prodSnap.exists) {
        final prod = Product.fromMap(prodSnap.id, prodSnap.data()!);
        final int theoreticalQty = prod.quantityInStock;
        final int countedQty = line.countedQuantity;
        final int diff = countedQty - theoreticalQty;

        // Mise à jour directe du stock
        await prodRef.update({
          'quantityInStock': countedQty,
          'dateUpdated': Timestamp.now(),
        });

        if (diff != 0) {
          final movement = StockMovement(
            id: _firestore.collection(_stockMovementsCol).doc().id,
            productId: prod.id,
            type: StockMovementType.ADJUSTMENT,
            quantity: diff.abs(),
            date: DateTime.now(),
            reference: 'InventoryCount:${count.id}',
            locationFrom: null,
            locationTo: null,
            userId: count.performedBy,
            reason: diff > 0 ? 'Revalorisation inventaire' : 'Écart d’inventaire',
            notes: 'Théorique: $theoreticalQty, Compté: $countedQty',
          );

          await _firestore
              .collection(_stockMovementsCol)
              .doc(movement.id)
              .set(movement.toMap());
        }
      }
    }
  }

  Future<void> deleteInventoryCount(String countId) async {
    await _firestore.collection(_inventoryCountsCol).doc(countId).delete();
  }

  // ─────────── RESTE : bons de commande, settings, permissions, etc. ───────────

  // ──────────────── FONCTIONS MÉTIERS / LOGICIELLE ────────────────

  Future<List<Product>> checkReorderAlerts() async {
    final allProducts = await fetchAllProducts();
    return allProducts
        .where((p) =>
    p.quantityInStock <= p.reorderThreshold &&
        p.quantityInStock > p.minimumStock)
        .toList();
  }

  Future<double> recalcStockValue() async {
    final products = await fetchAllProducts();
    return products.fold<double>(
      0.0,
          (total, p) => total + (p.costPrice * p.quantityInStock),
    );
  }

  Future<void> generateInventoryAdjustment({
    required String productId,
    required int countedQuantity,
    required String performedBy,
  }) async {
    final prodRef = _firestore.collection(_productsCol).doc(productId);
    final prodSnap = await prodRef.get();
    if (!prodSnap.exists) return;

    final prod = Product.fromMap(prodSnap.id, prodSnap.data()!);
    final diff = countedQuantity - prod.quantityInStock;
    if (diff == 0) return;

    await prodRef.update({
      'quantityInStock': countedQuantity,
      'dateUpdated': Timestamp.now(),
    });

    final movement = StockMovement(
      id: _firestore.collection(_stockMovementsCol).doc().id,
      productId: productId,
      type: StockMovementType.ADJUSTMENT,
      quantity: diff.abs(),
      date: DateTime.now(),
      reference: 'InventoryAdjustment',
      locationFrom: null,
      locationTo: null,
      userId: performedBy,
      reason: diff > 0 ? 'Récompte inventaire' : 'Écart inventaire',
      notes: 'Ancienne: ${prod.quantityInStock}, Compté: $countedQuantity',
    );

    await _firestore
        .collection(_stockMovementsCol)
        .doc(movement.id)
        .set(movement.toMap());
  }

}
