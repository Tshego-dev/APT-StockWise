import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/product.dart';
import '../../models/stock_transaction.dart';
import '../../services/database_service.dart';
import '../../services/inventory_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Product> _products = [];
  List<StockTransaction> _transactions = [];
  Map<String, int> _productQty = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final products = await DatabaseService.getProducts();
    final transactions = await DatabaseService.getTransactions();
    final qty = <String, int>{};
    for (final p in products) {
      qty[p.id] = await InventoryService.getTotalQuantity(p.id);
    }
    if (mounted) {
      setState(() {
        _products = products;
        _transactions = transactions;
        _productQty = qty;
        _loading = false;
      });
    }
  }

  double get _totalValue => _products.fold(
      0, (sum, p) => sum + (_productQty[p.id] ?? 0) * p.price);

  int get _totalSales => _transactions
      .where((t) => t.type == TransactionType.sale)
      .fold(0, (sum, t) => sum + t.quantity);

  List<BarChartGroupData> _buildBarData() {
    final top = _products.take(6).toList();
    return top.asMap().entries.map((e) {
      final qty = (_productQty[e.value.id] ?? 0).toDouble();
      return BarChartGroupData(
        x: e.key,
        barRods: [BarChartRodData(toY: qty, color: AppTheme.primary, width: 18, borderRadius: BorderRadius.circular(4))],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Total Stock Value',
                          value: DateFormatter.currency(_totalValue),
                          icon: Icons.attach_money,
                          color: AppTheme.safeColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Total Units Sold',
                          value: '$_totalSales',
                          icon: Icons.shopping_cart_outlined,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Bar chart
                  if (_products.isNotEmpty) ...[
                    Text('Stock Levels (Top Products)',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              barGroups: _buildBarData(),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) {
                                      final i = v.toInt();
                                      if (i >= _products.length) return const SizedBox();
                                      final name = _products[i].name;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          name.length > 8 ? '${name.substring(0, 8)}…' : name,
                                          style: const TextStyle(fontSize: 9),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: true),
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Recent transactions
                  Text('Recent Transactions',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_transactions.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No transactions recorded yet.'),
                      ),
                    )
                  else
                    ..._transactions.take(20).map((t) => _TransactionTile(
                          transaction: t,
                          productName: _products
                              .firstWhere((p) => p.id == t.productId,
                                  orElse: () => Product(
                                      id: '', name: 'Unknown', category: '',
                                      price: 0, minStockLevel: 0, targetStockLevel: 0,
                                      createdAt: DateTime.now()))
                              .name,
                        )),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final StockTransaction transaction;
  final String productName;
  const _TransactionTile({required this.transaction, required this.productName});

  @override
  Widget build(BuildContext context) {
    final typeLabels = {
      TransactionType.sale: ('Sale', AppTheme.secondary),
      TransactionType.stockIn: ('Stock In', AppTheme.safeColor),
      TransactionType.damaged: ('Damaged', AppTheme.expiryColor),
      TransactionType.disposal: ('Disposal', AppTheme.expiryColor),
      TransactionType.adjustment: ('Adjustment', AppTheme.warningColor),
    };
    final (label, color) = typeLabels[transaction.type]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.swap_horiz, color: color, size: 16),
        ),
        title: Text(productName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        subtitle: Text(DateFormatter.format(transaction.timestamp)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            Text('${transaction.quantity} units', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
