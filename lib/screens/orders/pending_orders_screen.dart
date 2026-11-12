import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class PendingOrder {
  final String id;
  final String customerName;
  final DateTime date;
  final double total;
  final List<PendingOrderItem> items;

  PendingOrder({
    required this.id,
    required this.customerName,
    required this.date,
    required this.total,
    required this.items,
  });
}

class PendingOrderItem {
  final int qty;
  final String name;
  PendingOrderItem({required this.qty, required this.name});
}

class PendingOrdersScreen extends StatefulWidget {
  const PendingOrdersScreen({super.key});

  @override
  State<PendingOrdersScreen> createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen> {
  final List<PendingOrder> _orders = [
    PendingOrder(
      id: '#A05436',
      customerName: 'Alex Smith',
      date: DateTime(2026, 9, 15),
      total: 542.00,
      items: [
        PendingOrderItem(qty: 1, name: 'Paracetamol 500mg'),
        PendingOrderItem(qty: 1, name: 'Vitamin C 1000mg'),
      ],
    ),
    PendingOrder(
      id: '#A05433',
      customerName: 'Fadhinha',
      date: DateTime(2026, 9, 15),
      total: 500.34,
      items: [
        PendingOrderItem(qty: 2, name: 'Ibuprofen 200mg'),
        PendingOrderItem(qty: 1, name: 'Cetirizine 10mg'),
        PendingOrderItem(qty: 1, name: 'Amoxicillin 250mg'),
      ],
    ),
    PendingOrder(
      id: '#A05430',
      customerName: 'Jhon Zaire',
      date: DateTime(2026, 9, 16),
      total: 300.34,
      items: [
        PendingOrderItem(qty: 1, name: 'Omeprazole 20mg'),
        PendingOrderItem(qty: 2, name: 'Metformin 500mg'),
      ],
    ),
    PendingOrder(
      id: '#A05433',
      customerName: 'David Cieriddeau',
      date: DateTime(2026, 9, 16),
      total: 500.34,
      items: [
        PendingOrderItem(qty: 1, name: 'Aspirin 100mg'),
        PendingOrderItem(qty: 2, name: 'Zinc Supplement'),
      ],
    ),
    PendingOrder(
      id: '#A05440',
      customerName: 'Sarah Mokoena',
      date: DateTime(2026, 9, 17),
      total: 389.00,
      items: [
        PendingOrderItem(qty: 3, name: 'Oral Rehydration Salts'),
        PendingOrderItem(qty: 1, name: 'Paracetamol 500mg'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: Row(
          children: [
            const Text('Pending Order List',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${_orders.length}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [IconButton(icon: const Icon(Icons.more_vert), onPressed: () {})],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (_, i) => _OrderCard(order: _orders[i]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final PendingOrder order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Text(order.id,
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(width: 10),
                Text(order.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(DateFormatter.format(order.date),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    Text(DateFormatter.currency(order.total),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const Divider(height: 16),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppTheme.secondary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text('${item.qty}×',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.secondary,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.inventory_2_outlined,
                                size: 12, color: AppTheme.primary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(item.name,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {},
                        child: const Text('Decline',
                            style: TextStyle(color: AppTheme.primary, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {},
                        child: const Text('Approve',
                            style: TextStyle(fontSize: 13, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
