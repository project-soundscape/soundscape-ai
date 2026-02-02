import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../data/services/appwrite_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/model_download_service.dart';
import '../../../data/services/audio_analysis_service.dart';
import '../../../routes/app_pages.dart';

class SettingsController extends GetxController {
  final _appwriteService = Get.find<AppwriteService>();
  final _storageService = Get.find<StorageService>();
  final _modelDownloadService = Get.find<ModelDownloadService>();
  final _analysisService = Get.find<AudioAnalysisService>();
  
  final appVersion = ''.obs;
  
  // UI State
  final isDarkMode = false.obs;
  final notificationsEnabled = true.obs;
  final showRecordingInstructions = true.obs;
  final activeModelId = 'yamnet'.obs;
  final downloadedModels = <String>{}.obs;

  bool get isLoggedIn => _appwriteService.isLoggedIn.value;
  String get userName => _appwriteService.currentUser.value?.name ?? 'Anonymous';
  String get userEmail => _appwriteService.currentUser.value?.email ?? 'No email';

  @override
  void onInit() {
    super.onInit();
    _loadAppVersion();
    _loadSettings();
    _checkAllModels();
  }

  Future<void> _checkAllModels() async {
    for (var model in _modelDownloadService.availableModels) {
      if (await _modelDownloadService.isModelDownloaded(model.id)) {
        downloadedModels.add(model.id);
      }
    }
  }

  void _loadSettings() {
    isDarkMode.value = _storageService.isDarkMode;
    notificationsEnabled.value = _storageService.notificationsEnabled;
    showRecordingInstructions.value = _storageService.showRecordingInstructions;
    activeModelId.value = _storageService.activeModelId;
    
    // Apply theme after build frame to avoid "setState called during build" error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    });
  }

  void toggleTheme(bool val) {
    isDarkMode.value = val;
    _storageService.isDarkMode = val;
    Get.changeThemeMode(val ? ThemeMode.dark : ThemeMode.light);
  }

  void toggleNotifications(bool val) {
    notificationsEnabled.value = val;
    _storageService.notificationsEnabled = val;
  }

  void toggleRecordingInstructions(bool val) {
    showRecordingInstructions.value = val;
    _storageService.showRecordingInstructions = val;
  }

  Future<void> setActiveModel(String id) async {
    if (id == 'yamnet') {
      _storageService.activeModelId = 'yamnet';
      activeModelId.value = 'yamnet';
      await _analysisService.reloadModel();
      return;
    }

    if (!downloadedModels.contains(id)) {
      final model = _modelDownloadService.availableModels.firstWhere((m) => m.id == id);
      await _modelDownloadService.downloadAcousticModel(model);
      await _checkAllModels();
      if (!downloadedModels.contains(id)) return; 
    }
    
    _storageService.activeModelId = id;
    activeModelId.value = id;
    await _analysisService.reloadModel();
  }

  Future<void> deleteAcousticModel(String id) async {
    await _modelDownloadService.deleteModel(id);
    downloadedModels.remove(id);
    if (activeModelId.value == id) {
      activeModelId.value = 'yamnet';
    }
    await _analysisService.reloadModel();
  }

  List<AcousticModel> get availableModels => _modelDownloadService.availableModels;
  RxDouble get downloadProgress => _modelDownloadService.downloadProgress;
  RxBool get isDownloading => _modelDownloadService.isDownloading;
  RxString get downloadStatus => _modelDownloadService.statusMessage;
  RxString get downloadingModelId => _modelDownloadService.downloadingModelId;

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    appVersion.value = '${info.version} (${info.buildNumber})';
  }

  Future<void> logout() async {
    await _appwriteService.logout();
    Get.offAllNamed(Routes.LOGIN);
  }

  Future<void> updateName(String name) async {
    try {
      await _appwriteService.updateName(name);
      Get.snackbar('Success', 'Name updated successfully', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''), backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> updatePassword(String newPassword, String oldPassword) async {
    try {
      await _appwriteService.updatePassword(newPassword, oldPassword);
      Get.snackbar('Success', 'Password updated successfully', backgroundColor: Colors.green, colorText: Colors.white);
      Get.back(); // Close dialog or page
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''), backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
