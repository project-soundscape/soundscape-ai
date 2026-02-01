import 'package:get/get.dart';
import '../../../data/models/recording_model.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/appwrite_service.dart';

class LibraryController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  
  final recordings = <Recording>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    
    // Listen to local changes reactively
    ever(_storageService.recordings, (List<Recording> local) {
      recordings.assignAll(local);
    });
    
    // Initial load
    recordings.assignAll(_storageService.getRecordings());
    
    loadRecordings();
  }

  Future<void> loadRecordings() async {
    isLoading.value = true;
    try {
      // 1. Fetch Remote
      final remote = await _appwriteService.getUserRecordings();
      
      // 2. Sync remote to local storage (which will trigger the 'ever' listener)
      for (var rec in remote) {
         await _storageService.updateRecording(rec);
      }

    } catch (e) {
      print("Library: Error loading recordings: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh list when entering the tab
  void refreshList() {
    loadRecordings();
  }

  Future<void> deleteRecording(Recording recording) async {
    try {
      // Delete remote first
      await _appwriteService.deleteRecording(recording.id);
      // Delete local
      await _storageService.deleteRecording(recording.id);
      
      recordings.remove(recording);
    } catch (e) {
      print("Error deleting: $e");
      // Even if remote fails (e.g. offline), we might want to delete local?
      // For now, keep strictly synced.
      Get.snackbar('Error', 'Failed to delete recording');
    }
  }

  Future<void> editRecording(Recording recording, String newName) async {
    if (newName.isEmpty) return;
    try {
      recording.commonName = newName;
      recordings.refresh();
      
      await _appwriteService.updateRecordingMetadata(recording.id, newName);
      await _storageService.updateRecording(recording);
      
      Get.snackbar('Updated', 'Recording renamed');
    } catch (e) {
       Get.snackbar('Error', 'Failed to update');
    }
  }
}
