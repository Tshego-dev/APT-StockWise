class Product {
  final String id;
  final String name;
  final String category;
  final String? barcode;
  final double price;
  final int minStockLevel;
  final int targetStockLevel;
  final String? description;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.category,
    this.barcode,
    required this.price,
    required this.minStockLevel,
    required this.targetStockLevel,
    this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'barcode': barcode,
        'price': price,
        'minStockLevel': minStockLevel,
        'targetStockLevel': targetStockLevel,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'],
        name: map['name'],
        category: map['category'],
        barcode: map['barcode'],
        price: (map['price'] as num).toDouble(),
        minStockLevel: map['minStockLevel'],
        targetStockLevel: map['targetStockLevel'],
        description: map['description'],
        createdAt: DateTime.parse(map['createdAt']),
      );
}
