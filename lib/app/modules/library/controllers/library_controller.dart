import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/recording_model.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/appwrite_service.dart';
import '../../../data/services/wiki_service.dart';

class LibraryController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  final WikiService _wikiService = Get.find<WikiService>();
  
  final recordings = <Recording>[].obs;
  final RxBool isLoading = false.obs;
  final searchQuery = ''.obs;
  final showOnlyMyRecordings = false.obs; // Filter toggle

  // Lightweight image cache
  final speciesImages = <String, String>{}.obs;
  final _loadingSpecies = <String>{};
  final _failedSpecies = <String>{};

  String? get currentUserId => _appwriteService.currentUserId;

  List<Recording> get filteredRecordings {
    List<Recording> results = recordings.toList();
    
    // Apply user filter
    if (showOnlyMyRecordings.value) {
      final currentUserId = _appwriteService.currentUserId;
      if (currentUserId != null) {
        results = results.where((rec) => rec.userId == currentUserId).toList();
      }
    }
    
    // Apply search filter
    if (searchQuery.isNotEmpty) {
      results = results.where((rec) {
        return (rec.commonName ?? '').toLowerCase().contains(searchQuery.value.toLowerCase());
      }).toList();
    }
    
    return results;
  }

  void toggleUserFilter() {
    showOnlyMyRecordings.value = !showOnlyMyRecordings.value;
  }

  /// Check if current user can delete this recording
  bool canDeleteRecording(Recording recording) {
    final currentUserId = _appwriteService.currentUserId;
    // Allow delete if: user not logged in (local only), or recording has no userId, or user owns it
    if (currentUserId == null) return true;
    if (recording.userId == null) return true;
    return recording.userId == currentUserId;
  }

  /// Lazy load species info for a specific recording
  Future<void> resolveSpeciesInfo(String? name) async {
    if (name == null || name.isEmpty) return;
    if (speciesImages.containsKey(name) || _loadingSpecies.contains(name) || _failedSpecies.contains(name)) return;

    final lowerName = name.toLowerCase();
    final invalidNames = {'silence', 'unknown', 'speech', 'music', 'human voice', 'background noise', 'unidentified bird'};
    if (invalidNames.contains(lowerName) || lowerName.contains('unidentified')) {
      _failedSpecies.add(name);
      return;
    }

    _loadingSpecies.add(name);
    try {
      final img = await _wikiService.getBirdImage(name);
      if (img != null) {
        speciesImages[name] = img;
      } else {
        _failedSpecies.add(name);
      }
    } catch (_) {
      _failedSpecies.add(name);
    } finally {
      _loadingSpecies.remove(name);
    }
  }

  /// Batch load images for visible items
  void refreshVisibleImages(int firstIndex, int lastIndex) async {
    final items = filteredRecordings;
    if (items.isEmpty) return;
    
    final start = firstIndex.clamp(0, items.length - 1);
    final end = lastIndex.clamp(0, items.length - 1);
    
    for (int i = start; i <= end; i++) {
      final name = items[i].commonName;
      if (name != null && !speciesImages.containsKey(name) && !_loadingSpecies.contains(name)) {
        resolveSpeciesInfo(name);
        // Small delay to prevent network congestion
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

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
      
      // 2. Sync remote to local storage
      for (var rec in remote) {
         final existing = _storageService.recordings.firstWhereOrNull((r) => r.id == rec.id);
         if (existing != null && existing.isLocal) {
            final file = File(existing.path);
            if (await file.exists()) {
               rec.path = existing.path;
            }
         }
         // updateRecording already triggers a refresh, but we're doing it in a loop
         await _storageService.updateRecording(rec);
      }

      // 3. Sync Deletions
      final localRecordings = _storageService.getRecordings();
      final remoteIds = remote.map((e) => e.id).toSet();
      
      for (var local in localRecordings) {
        if ((local.status == 'uploaded' || local.status == 'processed') && 
            !remoteIds.contains(local.id)) {
           await _storageService.deleteRecording(local.id);
        }
      }
      
      // If we deleted anything, local storage will have updated its observable, 
      // which triggers our 'ever' listener.
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
    // Check if user owns this recording
    final currentUserId = _appwriteService.currentUserId;
    if (currentUserId != null && recording.userId != null && recording.userId != currentUserId) {
      Get.snackbar(
        'Permission Denied',
        'You can only delete your own recordings',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
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
      final user = _appwriteService.currentUser.value;
      final suffix = user?.name != null ? " (ID: ${user!.name})" : "";
      final finalName = "$newName$suffix";
      
      recording.commonName = finalName;
      recordings.refresh();
      
      await _appwriteService.updateRecordingMetadata(recording.id, finalName);
      await _storageService.updateRecording(recording);
      
      Get.snackbar('Updated', 'Recording renamed');
    } catch (e) {
       Get.snackbar('Error', 'Failed to update');
    }
  }
}
