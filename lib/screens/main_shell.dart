import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'products/product_list_screen.dart';
import 'alerts/alerts_screen.dart';
import 'reports/reports_screen.dart';
import 'products/add_edit_product_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),
    ReportsScreen(),
    ProductListScreen(),
    AlertsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
        ),
        backgroundColor: AppTheme.safeColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.home_outlined, label: 'Home', index: 0, current: _currentIndex, onTap: _onTap),
            _NavItem(icon: Icons.show_chart_rounded, label: 'Activity', index: 1, current: _currentIndex, onTap: _onTap),
            const SizedBox(width: 48),
            _NavItem(icon: Icons.inventory_2_outlined, label: 'Inventory', index: 2, current: _currentIndex, onTap: _onTap),
            _NavItem(icon: Icons.notifications_outlined, label: 'Alerts', index: 3, current: _currentIndex, onTap: _onTap),
          ],
        ),
      ),
    );
  }

  void _onTap(int index) => setState(() => _currentIndex = index);
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected ? AppTheme.primary : Colors.grey[400],
                size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: selected ? AppTheme.primary : Colors.grey[400],
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
