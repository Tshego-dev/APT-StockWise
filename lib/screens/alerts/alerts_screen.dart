import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/stock_batch.dart';
import '../../services/database_service.dart';
import '../../services/inventory_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/expiry_badge.dart';
import '../products/product_detail_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<_LowStockAlert> _lowStock = [];
  List<_ExpiryAlert> _expiring = [];
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

    final lowStock = <_LowStockAlert>[];
    for (final p in products) {
      final total = await InventoryService.getTotalQuantity(p.id);
      if (total <= p.minStockLevel) {
        lowStock.add(_LowStockAlert(
          product: p,
          current: total,
          reorder: InventoryService.calculateReorderQuantity(total, p.targetStockLevel),
        ));
      }
    }

    final expiring = batches
        .where((b) => b.daysUntilExpiry <= 30)
        .map((b) {
          final product = products.firstWhere((p) => p.id == b.productId,
              orElse: () => Product(
                  id: '', name: 'Unknown', category: '', price: 0,
                  minStockLevel: 0, targetStockLevel: 0, createdAt: DateTime.now()));
          return _ExpiryAlert(batch: b, product: product);
        })
        .toList()
      ..sort((a, b) => a.batch.daysUntilExpiry.compareTo(b.batch.daysUntilExpiry));

    if (mounted) setState(() { _lowStock = lowStock; _expiring = expiring; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final totalAlerts = _lowStock.length + _expiring.length;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Alerts${totalAlerts > 0 ? ' ($totalAlerts)' : ''}'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: totalAlerts == 0
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: AppTheme.safeColor),
                          SizedBox(height: 12),
                          Text('All good! No alerts at this time.',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_lowStock.isNotEmpty) ...[
                          _SectionHeader(
                              icon: Icons.warning_amber_outlined,
                              label: 'Low Stock (${_lowStock.length})',
                              color: AppTheme.lowStockColor),
                          const SizedBox(height: 8),
                          ..._lowStock.map((a) => _LowStockCard(
                                alert: a,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ProductDetailScreen(product: a.product)),
                                ).then((_) => _load()),
                              )),
                          const SizedBox(height: 16),
                        ],
                        if (_expiring.isNotEmpty) ...[
                          _SectionHeader(
                              icon: Icons.schedule,
                              label: 'Expiring Soon (${_expiring.length})',
                              color: AppTheme.warningColor),
                          const SizedBox(height: 8),
                          ..._expiring.map((a) => _ExpiryCard(
                                alert: a,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ProductDetailScreen(product: a.product)),
                                ).then((_) => _load()),
                              )),
                        ],
                      ],
                    ),
            ),
    );
  }
}

class _LowStockAlert {
  final Product product;
  final int current;
  final int reorder;
  _LowStockAlert({required this.product, required this.current, required this.reorder});
}

class _ExpiryAlert {
  final StockBatch batch;
  final Product product;
  _ExpiryAlert({required this.batch, required this.product});
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
      ],
    );
  }
}

class _LowStockCard extends StatelessWidget {
  final _LowStockAlert alert;
  final VoidCallback onTap;
  const _LowStockCard({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFEDE5),
          child: Icon(Icons.inventory_2_outlined, color: AppTheme.lowStockColor),
        ),
        title: Text(alert.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${alert.current} units remaining • Min: ${alert.product.minStockLevel}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('Order ${alert.reorder}',
              style: const TextStyle(
                  color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }
}

class _ExpiryCard extends StatelessWidget {
  final _ExpiryAlert alert;
  final VoidCallback onTap;
  const _ExpiryCard({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFF3E0),
          child: Icon(Icons.schedule, color: AppTheme.warningColor),
        ),
        title: Text(alert.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${alert.batch.quantity} units • Expires: ${DateFormatter.format(alert.batch.expiryDate)}'),
        trailing: ExpiryBadge(daysUntilExpiry: alert.batch.daysUntilExpiry),
      ),
    );
  }
}
