import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/stock_batch.dart';
import '../models/stock_transaction.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'stockwise.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY, name TEXT, category TEXT, barcode TEXT,
        price REAL, minStockLevel INTEGER, targetStockLevel INTEGER,
        description TEXT, createdAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE stock_batches (
        id TEXT PRIMARY KEY, productId TEXT, quantity INTEGER,
        expiryDate TEXT, receivedDate TEXT, notes TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY, productId TEXT, batchId TEXT, type TEXT,
        quantity INTEGER, notes TEXT, timestamp TEXT, synced INTEGER DEFAULT 0
      )
    ''');
  }

  // Products
  static Future<void> upsertProduct(Product p) async {
    final db = await database;
    await db.insert('products', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Product>> getProducts() async {
    final db = await database;
    final rows = await db.query('products', orderBy: 'name ASC');
    return rows.map(Product.fromMap).toList();
  }

  static Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
    await db.delete('stock_batches', where: 'productId = ?', whereArgs: [id]);
  }

  // Batches
  static Future<void> upsertBatch(StockBatch b) async {
    final db = await database;
    await db.insert('stock_batches', b.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<StockBatch>> getBatchesForProduct(String productId) async {
    final db = await database;
    final rows = await db.query('stock_batches',
        where: 'productId = ? AND quantity > 0', whereArgs: [productId], orderBy: 'expiryDate ASC');
    return rows.map(StockBatch.fromMap).toList();
  }

  static Future<List<StockBatch>> getAllBatches() async {
    final db = await database;
    final rows = await db.query('stock_batches', where: 'quantity > 0', orderBy: 'expiryDate ASC');
    return rows.map(StockBatch.fromMap).toList();
  }

  static Future<void> updateBatchQuantity(String batchId, int quantity) async {
    final db = await database;
    await db.update('stock_batches', {'quantity': quantity},
        where: 'id = ?', whereArgs: [batchId]);
  }

  // Transactions
  static Future<void> insertTransaction(StockTransaction t) async {
    final db = await database;
    await db.insert('transactions', t.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<List<StockTransaction>> getTransactions({String? productId}) async {
    final db = await database;
    final rows = productId != null
        ? await db.query('transactions',
            where: 'productId = ?', whereArgs: [productId], orderBy: 'timestamp DESC')
        : await db.query('transactions', orderBy: 'timestamp DESC');
    return rows.map(StockTransaction.fromMap).toList();
  }

  static Future<List<StockTransaction>> getUnsyncedTransactions() async {
    final db = await database;
    final rows = await db.query('transactions', where: 'synced = 0');
    return rows.map(StockTransaction.fromMap).toList();
  }

  static Future<void> markTransactionSynced(String id) async {
    final db = await database;
    await db.update('transactions', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
