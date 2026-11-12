import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/product.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/inventory_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../analytics/stock_analytics_screen.dart';
import '../orders/pending_orders_screen.dart';
import '../products/add_edit_product_screen.dart';
import '../products/product_detail_screen.dart';
import '../products/barcode_scanner_screen.dart';
import '../transactions/stock_transaction_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _stats = {
    'totalProducts': 0,
    'totalValue': 0.0,
    'lowStockCount': 0,
    'expiringCount': 0,
  };
  List<Product> _topProducts = [];
  Map<String, int> _productQty = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final stats = await InventoryService.getDashboardStats();
    final products = await DatabaseService.getProducts();
    final qty = <String, int>{};
    for (final p in products) {
      qty[p.id] = await InventoryService.getTotalQuantity(p.id);
    }
    final sorted = [...products]..sort((a, b) => (qty[b.id] ?? 0).compareTo(qty[a.id] ?? 0));
    if (mounted) {
      setState(() {
        _stats = stats;
        _topProducts = sorted.take(5).toList();
        _productQty = qty;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildStatGrid(),
                        const SizedBox(height: 20),
                        _buildQuickActions(context),
                        const SizedBox(height: 20),
                        _buildOrderOverview(),
                        const SizedBox(height: 20),
                        _buildTopProducts(),
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      title: const Text('StockWise',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.black54),
          onPressed: _load,
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.black54),
          onPressed: () => AuthService().signOut(),
        ),
      ],
    );
  }

  Widget _buildStatGrid() {
    final cards = [
      _StatData('Total Products', '${_stats['totalProducts']}',
          [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)], Icons.inventory_2_rounded),
      _StatData('Pending Orders', '25',
          [const Color(0xFFEC4899), const Color(0xFFBE185D)], Icons.pending_actions_rounded),
      _StatData('Stock Available', '${_stats['totalProducts']}',
          [const Color(0xFF06B6D4), const Color(0xFF0284C7)], Icons.layers_rounded),
      _StatData('Stock Value', DateFormatter.currency(_stats['totalValue']),
          [const Color(0xFFF59E0B), const Color(0xFFD97706)], Icons.attach_money_rounded),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: cards.asMap().entries.map((e) => GestureDetector(
        onTap: () {
          if (e.key == 1) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PendingOrdersScreen()));
          } else if (e.key == 0 || e.key == 2) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const StockAnalyticsScreen()));
          }
        },
        child: _GradientStatCard(data: e.value),
      )).toList(),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions ✨',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _QuickActionTile(
          icon: Icons.add_box_outlined,
          label: 'Add a new item',
          onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddEditProductScreen()))
              .then((_) => _load()),
        ),
        const SizedBox(height: 8),
        _QuickActionTile(
          icon: Icons.qr_code_scanner,
          label: 'Scan barcode',
          onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()))
              .then((_) => _load()),
        ),
        const SizedBox(height: 8),
        _QuickActionTile(
          icon: Icons.point_of_sale_outlined,
          label: 'Record a sale',
          onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const StockTransactionScreen()))
              .then((_) => _load()),
        ),
        const SizedBox(height: 8),
        _QuickActionTile(
          icon: Icons.bar_chart_rounded,
          label: 'View stock analytics',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const StockAnalyticsScreen())),
        ),
        const SizedBox(height: 8),
        _QuickActionTile(
          icon: Icons.pending_actions_rounded,
          label: 'Pending orders',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PendingOrdersScreen())),
        ),
      ],
    );
  }

  Widget _buildOrderOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Overview',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          // Month selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep']
                  .asMap()
                  .entries
                  .map((e) {
                final selected = e.key == 8; // Sep
                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.secondary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(e.value,
                      style: TextStyle(
                          color: selected ? Colors.white : Colors.grey[500],
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const labels = ['1 Sep', '5 Sep', '10 Sep', '15 Sep', '20 Sep', '25 Sep'];
                        final i = v.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox();
                        return Text(labels[i],
                            style: const TextStyle(fontSize: 9, color: Colors.grey));
                      },
                      reservedSize: 22,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 20), FlSpot(1, 38), FlSpot(2, 28),
                      FlSpot(3, 50), FlSpot(4, 35), FlSpot(5, 55),
                    ],
                    isCurved: true,
                    color: AppTheme.secondary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.secondary.withOpacity(0.3),
                          AppTheme.secondary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Top Selling Product',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const StockAnalyticsScreen())),
              child: const Text('More', style: TextStyle(color: AppTheme.primary)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._topProducts.map((p) {
          final qty = _productQty[p.id] ?? 0;
          final isLow = qty <= p.minStockLevel;
          return GestureDetector(
            onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)))
                .then((_) => _load()),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(DateFormatter.currency(p.price),
                            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$qty Pcs',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(isLow ? 'Low Stock' : 'In Stock',
                          style: TextStyle(
                              fontSize: 11,
                              color: isLow ? AppTheme.lowStockColor : AppTheme.safeColor)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final List<Color> gradient;
  final IconData icon;
  _StatData(this.label, this.value, this.gradient, this.icon);
}

class _GradientStatCard extends StatelessWidget {
  final _StatData data;
  const _GradientStatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(data.icon, color: Colors.white.withOpacity(0.8), size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.value,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(data.label,
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11)),
              const SizedBox(height: 2),
              Text('Tap to View',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
