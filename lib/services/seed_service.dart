import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/stock_batch.dart';
import '../models/stock_transaction.dart';
import 'database_service.dart';

class SeedService {
  static const _key = 'seeded_v3';
  static const _uuid = Uuid();

  static Future<void> seedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_key) == true) return;

    // Base date: 15 Sep 2026
    final base = DateTime(2026, 9, 15);

    final products = [
      Product(id: _uuid.v4(), name: 'Paracetamol 500mg', category: 'Medication', price: 25.99, minStockLevel: 50, targetStockLevel: 200, description: 'Pain relief tablets', createdAt: base),
      Product(id: _uuid.v4(), name: 'Ibuprofen 200mg', category: 'Medication', price: 34.50, minStockLevel: 40, targetStockLevel: 150, description: 'Anti-inflammatory tablets', createdAt: base),
      Product(id: _uuid.v4(), name: 'Amoxicillin 250mg', category: 'Antibiotics', price: 89.00, minStockLevel: 30, targetStockLevel: 100, description: 'Broad-spectrum antibiotic', createdAt: base),
      Product(id: _uuid.v4(), name: 'Vitamin C 1000mg', category: 'Supplements', price: 45.00, minStockLevel: 60, targetStockLevel: 250, description: 'Immune support supplement', createdAt: base),
      Product(id: _uuid.v4(), name: 'Cetirizine 10mg', category: 'Allergy', price: 19.99, minStockLevel: 20, targetStockLevel: 80, description: 'Antihistamine for allergies', createdAt: base),
      Product(id: _uuid.v4(), name: 'Omeprazole 20mg', category: 'Gastro', price: 55.00, minStockLevel: 25, targetStockLevel: 100, description: 'Acid reflux treatment', createdAt: base),
      Product(id: _uuid.v4(), name: 'Metformin 500mg', category: 'Diabetes', price: 12.50, minStockLevel: 50, targetStockLevel: 200, description: 'Type 2 diabetes medication', createdAt: base),
      Product(id: _uuid.v4(), name: 'Aspirin 100mg', category: 'Medication', price: 8.99, minStockLevel: 10, targetStockLevel: 60, description: 'Low-dose aspirin', createdAt: base),
      Product(id: _uuid.v4(), name: 'Zinc Supplement', category: 'Supplements', price: 38.00, minStockLevel: 30, targetStockLevel: 120, description: 'Immune & wound healing support', createdAt: base),
      Product(id: _uuid.v4(), name: 'Oral Rehydration Salts', category: 'Gastro', price: 15.00, minStockLevel: 40, targetStockLevel: 160, description: 'Electrolyte replacement', createdAt: base),
    ];

    for (var i = 0; i < products.length; i++) {
      final p = products[i];
      await DatabaseService.upsertProduct(p);

      // Main batch — expires ~6–12 months from base
      final batchId = _uuid.v4();
      await DatabaseService.upsertBatch(StockBatch(
        id: batchId,
        productId: p.id,
        quantity: p.targetStockLevel ~/ 2,
        expiryDate: DateTime(2027, 3 + i, 15),
        receivedDate: base.subtract(const Duration(days: 10)),
      ));

      // Expiring-soon batch for every other product (~20–45 days from base)
      if (i % 2 == 0) {
        await DatabaseService.upsertBatch(StockBatch(
          id: _uuid.v4(),
          productId: p.id,
          quantity: p.targetStockLevel ~/ 4,
          expiryDate: base.add(Duration(days: 20 + i * 4)),
          receivedDate: base.subtract(const Duration(days: 30)),
          notes: 'Expiring soon batch',
        ));
      }

      // Seed stock-in transaction
      await DatabaseService.insertTransaction(StockTransaction(
        id: _uuid.v4(),
        productId: p.id,
        batchId: batchId,
        type: TransactionType.stockIn,
        quantity: p.targetStockLevel ~/ 2,
        timestamp: base.subtract(Duration(days: 10 + i)),
        synced: true,
      ));

      // Seed a sale transaction for most products
      if (i < 8) {
        await DatabaseService.insertTransaction(StockTransaction(
          id: _uuid.v4(),
          productId: p.id,
          batchId: batchId,
          type: TransactionType.sale,
          quantity: 5 + i * 2,
          timestamp: base.subtract(Duration(days: i + 1)),
          synced: true,
        ));
      }
    }

    await prefs.setBool(_key, true);
  }
}
