import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  final _isConnected = true.obs;
  bool get isConnected => _isConnected.value;
  RxBool get isConnectedRx => _isConnected;

  late StreamSubscription<List<ConnectivityResult>> _subscription;

  Future<ConnectivityService> init() async {
    // Initial check
    final results = await Connectivity().checkConnectivity();
    _updateStatus(results);

    // Listen for changes
    _subscription = Connectivity().onConnectivityChanged.listen(_updateStatus);
    
    return this;
  }

  void _updateStatus(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      _isConnected.value = false;
    } else {
      _isConnected.value = true;
    }
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }
}
