enum TransactionType { stockIn, sale, damaged, disposal, adjustment }

class StockTransaction {
  final String id;
  final String productId;
  final String? batchId;
  final TransactionType type;
  final int quantity;
  final String? notes;
  final DateTime timestamp;
  bool synced;

  StockTransaction({
    required this.id,
    required this.productId,
    this.batchId,
    required this.type,
    required this.quantity,
    this.notes,
    required this.timestamp,
    this.synced = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'productId': productId,
        'batchId': batchId,
        'type': type.name,
        'quantity': quantity,
        'notes': notes,
        'timestamp': timestamp.toIso8601String(),
        'synced': synced ? 1 : 0,
      };

  factory StockTransaction.fromMap(Map<String, dynamic> map) => StockTransaction(
        id: map['id'],
        productId: map['productId'],
        batchId: map['batchId'],
        type: TransactionType.values.byName(map['type']),
        quantity: map['quantity'],
        notes: map['notes'],
        timestamp: DateTime.parse(map['timestamp']),
        synced: map['synced'] == 1,
      );
}
