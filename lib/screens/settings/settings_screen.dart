import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storeNameCtrl = TextEditingController();
  bool _lowStockNotif = true;
  bool _expiryNotif = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _storeNameCtrl.text = prefs.getString('storeName') ?? '';
      _lowStockNotif = prefs.getBool('lowStockNotif') ?? true;
      _expiryNotif = prefs.getBool('expiryNotif') ?? true;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storeName', _storeNameCtrl.text.trim());
    await prefs.setBool('lowStockNotif', _lowStockNotif);
    await prefs.setBool('expiryNotif', _expiryNotif);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Settings saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      backgroundColor: AppTheme.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Store Details',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextFormField(
                      controller: _storeNameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Store Name', prefixIcon: Icon(Icons.store_outlined)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Notifications',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Low Stock Alerts'),
                        subtitle: const Text('Notify when stock falls below minimum'),
                        value: _lowStockNotif,
                        activeColor: AppTheme.primary,
                        onChanged: (v) => setState(() => _lowStockNotif = v),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Expiry Alerts'),
                        subtitle: const Text('Notify when batches are expiring soon'),
                        value: _expiryNotif,
                        activeColor: AppTheme.primary,
                        onChanged: (v) => setState(() => _expiryNotif = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: _save, child: const Text('Save Settings')),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout, color: AppTheme.expiryColor),
                  label: const Text('Sign Out', style: TextStyle(color: AppTheme.expiryColor)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.expiryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => AuthService().signOut(),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    super.dispose();
  }
}
