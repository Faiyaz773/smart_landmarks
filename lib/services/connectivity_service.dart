import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Fires every time connectivity changes, true = now online.
  static Stream<bool> onChange() {
    return Connectivity().onConnectivityChanged.map(
          (results) => !results.contains(ConnectivityResult.none),
        );
  }
}
