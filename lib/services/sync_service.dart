import 'package:connectivity_plus/connectivity_plus.dart';
import 'firestore_service.dart';

class SyncService {
  static final _firestore = FirestoreService();

  static void startListening() {
    Connectivity().onConnectivityChanged.listen((results) {
      final connected = results.any((r) => r != ConnectivityResult.none);
      if (connected) _firestore.pushPendingTransactions();
    });
  }

  static Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
