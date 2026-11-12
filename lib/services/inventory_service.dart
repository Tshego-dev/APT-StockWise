import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/stock_batch.dart';
import '../models/stock_transaction.dart';
import 'database_service.dart';
import 'firestore_service.dart';
import 'notification_service.dart';

class InventoryService {
  static final _uuid = Uuid();
  static final _firestore = FirestoreService();

  static Future<void> addProduct(Product product) async {
    await DatabaseService.upsertProduct(product);
    await _firestore.syncProduct(product);
  }

  static Future<void> updateProduct(Product product) async {
    await DatabaseService.upsertProduct(product);
    await _firestore.syncProduct(product);
  }

  static Future<void> deleteProduct(String id) async {
    await DatabaseService.deleteProduct(id);
    await _firestore.deleteProduct(id);
  }

  static Future<void> addBatch(StockBatch batch) async {
    await DatabaseService.upsertBatch(batch);
    await _firestore.syncBatch(batch);
  }

  static Future<int> getTotalQuantity(String productId) async {
    final batches = await DatabaseService.getBatchesForProduct(productId);
    return batches.fold<int>(0, (sum, b) => sum + b.quantity);
  }

  static Future<void> recordTransaction({
    required String productId,
    required String? batchId,
    required TransactionType type,
    required int quantity,
    String? notes,
  }) async {
    final t = StockTransaction(
      id: _uuid.v4(),
      productId: productId,
      batchId: batchId,
      type: type,
      quantity: quantity,
      notes: notes,
      timestamp: DateTime.now(),
    );

    await DatabaseService.insertTransaction(t);

    if (batchId != null) {
      final batches = await DatabaseService.getAllBatches();
      final batch = batches.firstWhere((b) => b.id == batchId);
      final delta = (type == TransactionType.stockIn) ? quantity : -quantity;
      final newQty = (batch.quantity + delta).clamp(0, 99999);
      await DatabaseService.updateBatchQuantity(batchId, newQty);
      batch.quantity = newQty;
      await _firestore.syncBatch(batch);
    }

    try {
      await _firestore.syncTransaction(t);
      await DatabaseService.markTransactionSynced(t.id);
    } catch (_) {
      // Will sync later when online
    }

    await _checkAlerts(productId);
  }

  static Future<void> _checkAlerts(String productId) async {
    final products = await DatabaseService.getProducts();
    final product = products.firstWhere((p) => p.id == productId, orElse: () => throw Exception());
    final total = await getTotalQuantity(productId);
    if (total <= product.minStockLevel) {
      final reorder = product.targetStockLevel - total;
      await NotificationService.showLowStockAlert(product.name, total, reorder);
    }
  }

  static int calculateReorderQuantity(int current, int target) =>
      (target - current).clamp(0, 99999);

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final products = await DatabaseService.getProducts();
    final batches = await DatabaseService.getAllBatches();

    int totalProducts = products.length;
    double totalValue = 0;
    int lowStockCount = 0;
    int expiringCount = 0;

    for (final product in products) {
      final productBatches = batches.where((b) => b.productId == product.id).toList();
      final total = productBatches.fold(0, (s, b) => s + b.quantity);
      totalValue += total * product.price;
      if (total <= product.minStockLevel) lowStockCount++;
    }

    for (final batch in batches) {
      if (batch.isExpiringSoon) expiringCount++;
    }

    return {
      'totalProducts': totalProducts,
      'totalValue': totalValue,
      'lowStockCount': lowStockCount,
      'expiringCount': expiringCount,
    };
  }
}
