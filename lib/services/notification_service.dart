import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
  }

  static Future<void> showLowStockAlert(String productName, int current, int reorder) async {
    await _plugin.show(
      productName.hashCode,
      'Low Stock: $productName',
      'Only $current units left. Reorder $reorder units.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'low_stock', 'Low Stock Alerts',
          importance: Importance.high, priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> showExpiryAlert(String productName, int daysLeft) async {
    await _plugin.show(
      '${productName}_expiry'.hashCode,
      'Expiry Warning: $productName',
      daysLeft == 0 ? 'A batch expires today!' : 'A batch expires in $daysLeft day(s).',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'expiry', 'Expiry Alerts',
          importance: Importance.high, priority: Priority.high,
        ),
      ),
    );
  }
}
