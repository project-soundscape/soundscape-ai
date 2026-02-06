import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/recording_model.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/appwrite_service.dart';
import '../../../data/services/wiki_service.dart';
import 'package:frontend/app/utils/snackbar_utils.dart';

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
    
    // Apply search filter locally (Old Style)
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      results = results.where((rec) {
        final nameMatch = (rec.commonName ?? '').toLowerCase().contains(query);
        final idMatch = rec.id.toLowerCase().contains(query);
        return nameMatch || idMatch;
      }).toList();
    }
    
    return results;
  }

  void toggleUserFilter() {
    showOnlyMyRecordings.value = !showOnlyMyRecordings.value;
  }

  /// Check if current user can delete this recording
  bool canDeleteRecording(Recording recording) {
    final currentUser = _appwriteService.currentUser.value;
    if (currentUser?.email == 'androlite4@gmail.com') return true;
    
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
      await _appwriteService.syncWithRemote();
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

  Future<void> deleteRecording(Recording recording, BuildContext context) async {
    // Check if user owns this recording or is admin
    final currentUser = _appwriteService.currentUser.value;
    final isAdmin = currentUser?.email == 'androlite4@gmail.com';
    
    if (!isAdmin && currentUser?.$id != null && recording.userId != null && recording.userId != currentUser?.$id) {
      showCustomSnackBar('Permission Denied', 'You can only delete your own recordings');
      return;
    }
    
    bool isUndone = false;
    
    // 1. Remove from local storage immediately to update UI
    await _storageService.deleteRecording(recording.id);
    
    // 2. Show Snackbar with Undo action
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Recording deleted", style: TextStyle(color: Colors.white)),
        action: SnackBarAction(
          label: "UNDO",
          textColor: Colors.amber,
          onPressed: () {
            isUndone = true;
          },
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
        backgroundColor: Colors.grey[900],
      ),
    );

    // 3. Wait for snackbar to potentially be undone
    await Future.delayed(const Duration(seconds: 4));
    
    if (isUndone) {
      // 4. Restore if undone
      await _storageService.saveRecording(recording);
      return;
    }

    try {
      // 5. Actually delete from remote
      await _appwriteService.deleteRecording(recording.id);
    } catch (e) {
      print("Error deleting from remote: $e");
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
      
      showCustomSnackBar('Updated', 'Recording renamed', isError: false);
    } catch (e) {
       showCustomSnackBar('Error', 'Failed to update');
    }
  }
}
