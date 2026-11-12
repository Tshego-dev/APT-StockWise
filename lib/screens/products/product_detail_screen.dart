import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/stock_batch.dart';
import '../../models/stock_transaction.dart';
import '../../services/database_service.dart';
import '../../services/inventory_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/expiry_badge.dart';
import 'add_edit_product_screen.dart';
import '../transactions/add_batch_screen.dart';
import '../transactions/stock_transaction_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<StockBatch> _batches = [];
  List<StockTransaction> _transactions = [];
  int _totalQty = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final batches = await DatabaseService.getBatchesForProduct(widget.product.id);
    final total = await InventoryService.getTotalQuantity(widget.product.id);
    final txns = await DatabaseService.getTransactions(productId: widget.product.id);
    if (mounted) {
      setState(() {
        _batches = batches;
        _totalQty = total;
        _transactions = txns.take(5).toList();
        _loading = false;
      });
    }
  }

  bool get _isLowStock => _totalQty <= widget.product.minStockLevel;
  bool get _isOutOfStock => _totalQty == 0;

  String get _statusLabel {
    if (_isOutOfStock) return 'Out of stock';
    if (_isLowStock) return 'Low stock';
    return 'In stock';
  }

  Color get _statusColor {
    if (_isOutOfStock) return AppTheme.expiryColor;
    if (_isLowStock) return AppTheme.lowStockColor;
    return AppTheme.safeColor;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('Inventory item',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () => _showOptions(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(p),
                  const SizedBox(height: 16),
                  _buildStockSummary(p),
                  const SizedBox(height: 16),
                  _buildActionButtons(p),
                  const SizedBox(height: 16),
                  _buildBatchLocations(),
                  const SizedBox(height: 16),
                  _buildRecentActivity(),
                  const SizedBox(height: 16),
                  _buildViewHistoryButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(Product p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                color: AppTheme.primary, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 17)),
                if (p.barcode != null)
                  Text('SKU: ${p.barcode}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_statusLabel,
                      style: TextStyle(
                          color: _statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockSummary(Product p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('On hand', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$_totalQty',
                  style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _isLowStock ? AppTheme.lowStockColor : Colors.black87)),
              const SizedBox(width: 6),
              Text('units',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(p.category,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    Text('$_totalQty units',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Min Level',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    Text('${p.minStockLevel} units',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_totalQty / p.targetStockLevel).clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            color: _statusColor,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Product p) {
    return Row(
      children: [
        _ActionBtn(
          icon: Icons.add_box_outlined,
          label: 'Add Batch',
          onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AddBatchScreen(product: p)))
              .then((_) => _load()),
        ),
        const SizedBox(width: 10),
        _ActionBtn(
          icon: Icons.point_of_sale_outlined,
          label: 'Record Sale',
          onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => StockTransactionScreen(product: p)))
              .then((_) => _load()),
        ),
        const SizedBox(width: 10),
        _ActionBtn(
          icon: Icons.tune_outlined,
          label: 'Adjust',
          onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AddEditProductScreen(product: p)))
              .then((_) => _load()),
        ),
      ],
    );
  }

  Widget _buildBatchLocations() {
    if (_batches.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Batches',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${_batches.length}',
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ],
              ),
              Text('On hand',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          ..._batches.asMap().entries.map((e) {
            final b = e.value;
            final isCurrent = e.key == 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppTheme.primary.withOpacity(0.05)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: isCurrent
                    ? Border.all(color: AppTheme.primary.withOpacity(0.2))
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Batch ${e.key + 1}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('Expires ${DateFormatter.format(b.expiryDate)}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Current',
                          style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${b.quantity}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('units',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 11)),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Text('Quantities shown per batch',
              style: TextStyle(color: Colors.grey[400], fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_transactions.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent activity',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          ..._transactions.map((t) {
            final typeLabels = {
              TransactionType.sale: ('Sale', AppTheme.secondary),
              TransactionType.stockIn: ('Stock In', AppTheme.safeColor),
              TransactionType.damaged: ('Damaged', AppTheme.expiryColor),
              TransactionType.disposal: ('Disposal', AppTheme.expiryColor),
              TransactionType.adjustment: ('Adjustment', AppTheme.warningColor),
            };
            final (label, color) = typeLabels[t.type]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.access_time, color: color, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 13)),
                        Text(DateFormatter.format(t.timestamp),
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 11)),
                      ],
                    ),
                  ),
                  Text('${t.quantity} units',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildViewHistoryButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.lowStockColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.history),
        label: const Text('View stock history →'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => StockTransactionScreen(product: widget.product)),
        ).then((_) => _load()),
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit product'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) =>
                              AddEditProductScreen(product: widget.product)))
                  .then((_) => _load());
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete product',
                style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await InventoryService.deleteProduct(widget.product.id);
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primary, size: 22),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
