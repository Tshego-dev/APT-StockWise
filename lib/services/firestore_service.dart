import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../models/stock_batch.dart';
import '../models/stock_transaction.dart';
import 'database_service.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _products => _db.collection('users/$_uid/products');
  CollectionReference get _batches => _db.collection('users/$_uid/batches');
  CollectionReference get _transactions => _db.collection('users/$_uid/transactions');

  Future<void> syncProduct(Product p) => _products.doc(p.id).set(p.toMap());

  Future<void> deleteProduct(String id) => _products.doc(id).delete();

  Future<void> syncBatch(StockBatch b) => _batches.doc(b.id).set(b.toMap());

  Future<void> syncTransaction(StockTransaction t) =>
      _transactions.doc(t.id).set(t.toMap());

  Future<void> pullFromCloud() async {
    final products = await _products.get();
    for (final doc in products.docs) {
      await DatabaseService.upsertProduct(Product.fromMap(doc.data() as Map<String, dynamic>));
    }
    final batches = await _batches.get();
    for (final doc in batches.docs) {
      await DatabaseService.upsertBatch(StockBatch.fromMap(doc.data() as Map<String, dynamic>));
    }
  }

  Future<void> pushPendingTransactions() async {
    final pending = await DatabaseService.getUnsyncedTransactions();
    for (final t in pending) {
      await syncTransaction(t);
      await DatabaseService.markTransactionSynced(t.id);
    }
  }
}
