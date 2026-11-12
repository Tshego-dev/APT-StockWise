class StockBatch {
  final String id;
  final String productId;
  int quantity;
  final DateTime expiryDate;
  final DateTime receivedDate;
  final String? notes;

  StockBatch({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.expiryDate,
    required this.receivedDate,
    this.notes,
  });

  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;
  bool get isExpired => daysUntilExpiry < 0;
  bool get isExpiringSoon => daysUntilExpiry >= 0 && daysUntilExpiry <= 30;

  Map<String, dynamic> toMap() => {
        'id': id,
        'productId': productId,
        'quantity': quantity,
        'expiryDate': expiryDate.toIso8601String(),
        'receivedDate': receivedDate.toIso8601String(),
        'notes': notes,
      };

  factory StockBatch.fromMap(Map<String, dynamic> map) => StockBatch(
        id: map['id'],
        productId: map['productId'],
        quantity: map['quantity'],
        expiryDate: DateTime.parse(map['expiryDate']),
        receivedDate: DateTime.parse(map['receivedDate']),
        notes: map['notes'],
      );
}
