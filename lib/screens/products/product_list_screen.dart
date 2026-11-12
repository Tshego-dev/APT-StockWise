import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/database_service.dart';
import '../../services/inventory_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import 'add_edit_product_screen.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> _products = [];
  List<Product> _filtered = [];
  Map<String, int> _qty = {};
  Map<String, DateTime?> _nearestExpiry = {};
  String _search = '';
  String? _categoryFilter;
  String _stockFilter = 'All';
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
    final qty = <String, int>{};
    final expiry = <String, DateTime?>{};
    for (final p in products) {
      final pb = batches.where((b) => b.productId == p.id).toList();
      qty[p.id] = pb.fold(0, (s, b) => s + b.quantity);
      final sorted = [...pb]..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      expiry[p.id] = sorted.isNotEmpty ? sorted.first.expiryDate : null;
    }
    if (mounted) {
      setState(() {
        _products = products;
        _qty = qty;
        _nearestExpiry = expiry;
        _applyFilter();
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    _filtered = _products.where((p) {
      final matchSearch = p.name.toLowerCase().contains(_search.toLowerCase()) ||
          (p.barcode?.contains(_search) ?? false);
      final matchCategory = _categoryFilter == null || p.category == _categoryFilter;
      final q = _qty[p.id] ?? 0;
      final matchStock = _stockFilter == 'All' ||
          (_stockFilter == 'Low stock' && q <= p.minStockLevel);
      return matchSearch && matchCategory && matchStock;
    }).toList();
  }

  Future<void> _delete(Product p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${p.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.expiryColor),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await InventoryService.deleteProduct(p.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterChips(),
            _buildSearchBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? const Center(child: Text('No products found', style: TextStyle(color: Colors.black54)))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.78,
                            ),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _ProductGridCard(
                              product: _filtered[i],
                              qty: _qty[_filtered[i].id] ?? 0,
                              nearestExpiry: _nearestExpiry[_filtered[i].id],
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => ProductDetailScreen(product: _filtered[i])))
                                  .then((_) => _load()),
                              onEdit: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => AddEditProductScreen(product: _filtered[i])))
                                  .then((_) => _load()),
                              onDelete: () => _delete(_filtered[i]),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showCategoryPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.grid_view_rounded, color: Colors.black54, size: 18),
                  const SizedBox(width: 6),
                  Text(_categoryFilter ?? 'All Categories',
                      style: const TextStyle(color: Colors.black87, fontSize: 13)),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: ['All', 'Low stock'].map((label) {
          final selected = _stockFilter == label;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() { _stockFilter = label; _applyFilter(); }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.safeColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? AppTheme.safeColor : Colors.grey.shade300),
                ),
                child: Text(label,
                    style: TextStyle(
                        color: selected ? Colors.white : Colors.black54,
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (v) => setState(() { _search = v; _applyFilter(); }),
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('All Categories'),
            onTap: () { setState(() { _categoryFilter = null; _applyFilter(); }); Navigator.pop(context); },
          ),
          ...AppConstants.categories.map((c) => ListTile(
                title: Text(c),
                onTap: () { setState(() { _categoryFilter = c; _applyFilter(); }); Navigator.pop(context); },
              )),
        ],
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final Product product;
  final int qty;
  final DateTime? nearestExpiry;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductGridCard({
    required this.product,
    required this.qty,
    required this.nearestExpiry,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  String get _statusLabel {
    if (qty == 0) return 'Out of stock';
    if (qty <= product.minStockLevel) return 'Low stock';
    return 'In stock';
  }

  Color get _statusColor {
    if (qty == 0) return AppTheme.expiryColor;
    if (qty <= product.minStockLevel) return AppTheme.lowStockColor;
    return AppTheme.safeColor;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Center(
                    child: Icon(Icons.inventory_2_outlined, color: Colors.grey.shade300, size: 48),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_statusLabel,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 18),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                    onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (nearestExpiry != null) ...[
                    const SizedBox(height: 2),
                    Text('Expires ${DateFormatter.format(nearestExpiry!)}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 6),
                  Text('$qty  $_statusLabel',
                      style: TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
