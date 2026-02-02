import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'storage_service.dart';

class ModelDownloadService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();

  final RxDouble downloadProgress = 0.0.obs;
  final RxBool isDownloading = false.obs;
  final RxString statusMessage = ''.obs;

  // Official Kaggle Download URL provided by user
  static const String modelDownloadUrl = "https://www.kaggle.com/api/v1/models/shadiakiki1/birdnet-analyzer/tfLite/birdnet_global_6k_v2.4_model_fp32-1/3/download";

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
    statusMessage.value = "Connecting to Kaggle...";
    downloadProgress.value = 0.0;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelDir = Directory('${appDir.path}/models');
      if (!await modelDir.exists()) {
        await modelDir.create(recursive: true);
      }

      final tempZipPath = '${appDir.path}/models/model_bundle.tar.gz';
      
      final dio = Dio(BaseOptions(
        followRedirects: true,
        maxRedirects: 10,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(minutes: 15),
      ));

      // 1. Download the Tarball/Zip
      statusMessage.value = "Downloading Model Package...";
      await dio.download(
        modelDownloadUrl,
        tempZipPath,
        onReceiveProgress: (count, total) {
          if (total > 0) {
            downloadProgress.value = (count / total);
          }
        },
      );

      statusMessage.value = "Extracting files...";
      
      final bytes = File(tempZipPath).readAsBytesSync();
      
      // Handle .tar.gz (GZip + Tar)
      final gzipBytes = GZipDecoder().decodeBytes(bytes);
      final archive = TarDecoder().decodeBytes(gzipBytes);

      String? modelPath;
      String? labelsPath;

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          if (filename.toLowerCase().endsWith('.tflite')) {
            final f = File('${modelDir.path}/birdnet.tflite');
            f.writeAsBytesSync(data);
            modelPath = f.path;
          } else if (filename.toLowerCase().contains('label')) {
            final f = File('${modelDir.path}/birdnet_labels.txt');
            f.writeAsBytesSync(data);
            labelsPath = f.path;
          }
        }
      }

      // Cleanup
      if (await File(tempZipPath).exists()) await File(tempZipPath).delete();

      if (modelPath != null && labelsPath != null) {
        statusMessage.value = "Intelligence Upgraded!";
        _storage.useAdvancedModel = true;
        _showSafeSnackbar("Success", "BirdNET-Analyzer is now active.");
      } else {
        throw Exception("Required files not found in the package.");
      }

    } catch (e) {
      statusMessage.value = "Download failed. Check your connection.";
      print("ModelDownload Error: $e");
      _showSafeSnackbar("Download Error", "Could not process the Kaggle package.");
    } finally {
      isDownloading.value = false;
    }
  }

  void _showSafeSnackbar(String title, String message) {
    try {
      Get.rawSnackbar(
        title: title,
        message: message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.teal.withOpacity(0.9),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      print("Snackbar failed: $e");
    }
  }

  Future<void> deleteModel() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelFile = File('${appDir.path}/models/birdnet.tflite');
    final labelsFile = File('${appDir.path}/models/birdnet_labels.txt');
    
    if (await modelFile.exists()) await modelFile.delete();
    if (await labelsFile.exists()) await labelsFile.delete();
    
    _storage.useAdvancedModel = false;
    statusMessage.value = "Model deleted.";
  }
}
