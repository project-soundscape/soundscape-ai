import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'storage_service.dart';
import 'appwrite_service.dart';
import 'notification_service.dart';
import '../models/recording_model.dart';

class SyncService extends GetxService {
  final StorageService _storageService = Get.find<StorageService>();
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  
  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;

  Future<SyncService> init() async {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        syncNow();
      }
    });
    
    // Periodically try to sync every 5 minutes
    Timer.periodic(const Duration(minutes: 5), (timer) {
      syncNow();
    });

    return this;
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  Future<void> syncNow() async {
    if (_isSyncing) return;
    
    final results = await Connectivity().checkConnectivity();
    if (results.isEmpty || results.contains(ConnectivityResult.none)) return;

    _isSyncing = true;
    print("SyncService: Starting sync...");

    try {
      final recordings = _storageService.getRecordings();
      final toUpload = recordings.where((r) => r.status == 'pending' || r.status == 'failed').toList();

      if (toUpload.isEmpty) return;

      int successCount = 0;
      for (var recording in toUpload) {
        try {
          await _appwriteService.uploadRecording(recording);
          successCount++;
        } catch (e) {
          print("SyncService: Failed to upload ${recording.id}: $e");
        }
      }

      if (successCount > 0) {
        Get.find<NotificationService>().showNotification(
          id: 999,
          title: 'Sync Complete',
          body: '$successCount recordings uploaded successfully.',
        );
      }
    } finally {
      _isSyncing = false;
      print("SyncService: Sync finished.");
    }
  }
}
