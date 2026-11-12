import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/stock_transaction.dart';
import '../../services/database_service.dart';
import '../../services/inventory_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../products/add_edit_product_screen.dart';
import '../products/product_detail_screen.dart';

class StockAnalyticsScreen extends StatefulWidget {
  const StockAnalyticsScreen({super.key});

  @override
  State<StockAnalyticsScreen> createState() => _StockAnalyticsScreenState();
}

class _StockAnalyticsScreenState extends State<StockAnalyticsScreen> {
  List<Product> _products = [];
  Map<String, int> _qty = {};
  int _totalIn = 0;
  int _totalOut = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final products = await DatabaseService.getProducts();
    final batches = await DatabaseService.getAllBatches();
    final txns = await DatabaseService.getTransactions();

    final qty = <String, int>{};
    for (final p in products) {
      final pb = batches.where((b) => b.productId == p.id).toList();
      qty[p.id] = pb.fold(0, (s, b) => s + b.quantity);
    }

    final totalIn = txns
        .where((t) => t.type == TransactionType.stockIn)
        .fold(0, (s, t) => s + t.quantity);
    final totalOut = txns
        .where((t) => t.type == TransactionType.sale || t.type == TransactionType.damaged)
        .fold(0, (s, t) => s + t.quantity);

    if (mounted) {
      setState(() {
        _products = products;
        _qty = qty;
        _totalIn = totalIn;
        _totalOut = totalOut;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('Stock Analytics',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [IconButton(icon: const Icon(Icons.more_vert), onPressed: () {})],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildInOutCards(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const AddEditProductScreen()))
                          .then((_) => _load()),
                      child: const Text('Add Product',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Available Product List',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ..._products.map((p) => _ProductListTile(
                        product: p,
                        qty: _qty[p.id] ?? 0,
                        onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)))
                            .then((_) => _load()),
                      )),
                ],
              ),
            ),
    );
  }

  Widget _buildInOutCards() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB44FE8), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_totalIn',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Product In', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_totalOut',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Product Out', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductListTile extends StatelessWidget {
  final Product product;
  final int qty;
  final VoidCallback onTap;

  const _ProductListTile({required this.product, required this.qty, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(DateFormatter.currency(product.price),
                          style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$qty Pcs',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('In Stock', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${product.targetStockLevel} Pcs',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Last Restock', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
