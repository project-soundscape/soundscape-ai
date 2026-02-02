import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';

class ModelDownloadService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();

  final RxDouble downloadProgress = 0.0.obs;
  final RxBool isDownloading = false.obs;
  final RxString statusMessage = ''.obs;

  // BirdNET-Lite Model (Proven, high-performance alternative)
  static const String modelUrl = "https://github.com/kahst/BirdNET-Lite/raw/main/model/BirdNET_6K_GLOBAL_pub_model.tflite";
  static const String labelsUrl = "https://github.com/kahst/BirdNET-Lite/raw/main/model/labels.txt";

  Future<bool> isModelDownloaded() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelFile = File('${appDir.path}/models/birdnet.tflite');
    final labelsFile = File('${appDir.path}/models/birdnet_labels.txt');
    
    if (!await modelFile.exists() || !await labelsFile.exists()) return false;
    
    final modelSize = await modelFile.length();
    return modelSize > 5 * 1024 * 1024; 
  }

  Future<void> downloadModel() async {
    if (isDownloading.value) return;

    isDownloading.value = true;
    statusMessage.value = "Connecting to repository...";
    downloadProgress.value = 0.0;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelDir = Directory('${appDir.path}/models');
      if (!await modelDir.exists()) {
        await modelDir.create(recursive: true);
      }

      final modelPath = '${modelDir.path}/birdnet.tflite';
      final labelsPath = '${modelDir.path}/birdnet_labels.txt';

      // Use a custom Dio instance for reliable redirects
      final dio = Dio(BaseOptions(
        followRedirects: true,
        maxRedirects: 5,
        connectTimeout: const Duration(seconds: 30),
      ));

      // 1. Download Model
      statusMessage.value = "Downloading Neural Engine (15MB)...";
      await dio.download(
        modelUrl,
        modelPath,
        onReceiveProgress: (count, total) {
          if (total > 0) {
            downloadProgress.value = (count / total) * 0.9;
          }
        },
      );

      // 2. Download Labels
      statusMessage.value = "Downloading labels...";
      await dio.download(
        labelsUrl,
        labelsPath,
      );

      // Final Format Validation
      final modelFile = File(modelPath);
      final bytes = await modelFile.readAsBytes();
      
      bool isValid = false;
      if (bytes.length > 8) {
        final magic = String.fromCharCodes(bytes.sublist(4, 8));
        if (magic == 'TFL3') isValid = true;
      }

      if (isValid) {
        statusMessage.value = "Download complete!";
        _storage.usePerchModel = true; // Flag for advanced model use
        _showSafeSnackbar("Intelligence Upgraded", "BirdNET-Lite is now active.");
      } else {
        await deleteModel();
        throw Exception("Invalid model file format.");
      }

    } catch (e) {
      statusMessage.value = "Download failed. Check your connection.";
      print("ModelDownload Error: $e");
      _showSafeSnackbar("Download Error", "Could not retrieve the acoustic model.");
    } finally {
      isDownloading.value = false;
    }
  }

  void _showSafeSnackbar(String title, String message) {
    if (Get.isSnackbarOpen) return;
    
    try {
      Get.rawSnackbar(
        title: title,
        message: message,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        backgroundColor: Colors.teal.withOpacity(0.9),
      );
    } catch (e) {
      print("Snackbar Error: $e");
    }
  }

  Future<void> deleteModel() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelFile = File('${appDir.path}/models/birdnet.tflite');
    final labelsFile = File('${appDir.path}/models/birdnet_labels.txt');
    
    if (await modelFile.exists()) await modelFile.delete();
    if (await labelsFile.exists()) await labelsFile.delete();
    
    _storage.usePerchModel = false;
    statusMessage.value = "Model deleted.";
  }
}