import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'storage_service.dart';

class AcousticModel {
  final String id;
  final String name;
  final String description;
  final String downloadUrl;
  final String labelsUrl;
  final bool isArchive;
  final int sampleRate;
  final int inputSize;

  AcousticModel({
    required this.id,
    required this.name,
    required this.description,
    required this.downloadUrl,
    required this.labelsUrl,
    this.isArchive = false,
    this.sampleRate = 48000,
    this.inputSize = 144000,
  });
}

class ModelDownloadService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();

  final RxDouble downloadProgress = 0.0.obs;
  final RxBool isDownloading = false.obs;
  final RxString statusMessage = ''.obs;
  final RxString downloadingModelId = ''.obs;

  final List<AcousticModel> availableModels = [
    AcousticModel(
      id: 'birdnet_v2.4',
      name: 'BirdNET-Analyzer v2.4',
      description: 'The Gold Standard: 6,500+ species with high precision. (Kaggle Bundle)',
      downloadUrl: "https://www.kaggle.com/api/v1/models/shadiakiki1/birdnet-analyzer/tfLite/birdnet_global_6k_v2.4_model_fp32-1/3/download",
      labelsUrl: "", // Included in archive
      isArchive: true,
      sampleRate: 48000,
      inputSize: 144000,
    ),
  ];

  Future<bool> isModelDownloaded(String id) async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelFile = File('${appDir.path}/models/$id.tflite');
    final labelsFile = File('${appDir.path}/models/${id}_labels.txt');
    
    if (!await modelFile.exists()) return false;
    
    final modelSize = await modelFile.length();
    return modelSize > 1 * 1024 * 1024; // At least 1MB
  }

  Future<void> downloadAcousticModel(AcousticModel model) async {
    if (isDownloading.value) return;

    isDownloading.value = true;
    downloadingModelId.value = model.id;
    statusMessage.value = "Connecting...";
    downloadProgress.value = 0.0;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelDir = Directory('${appDir.path}/models');
      if (!await modelDir.exists()) await modelDir.create(recursive: true);

      final dio = Dio(BaseOptions(
        followRedirects: true,
        maxRedirects: 15,
        connectTimeout: const Duration(seconds: 60),
        headers: {
          'User-Agent': 'SoundScape-Mobile/1.0',
        },
      ));

      if (model.isArchive) {
        await _downloadAndExtract(dio, model, modelDir);
      } else {
        await _downloadDirect(dio, model, modelDir);
      }

      statusMessage.value = "Download complete!";
      _storage.activeModelId = model.id;
      _storage.useAdvancedModel = true;
      
      _showSafeSnackbar("Intelligence Upgraded", "${model.name} is now active.");

    } catch (e) {
      statusMessage.value = "Download failed.";
      print("ModelDownload Error: $e");
      _showSafeSnackbar("Download Error", "Could not retrieve the model package. Status: $e");
    } finally {
      isDownloading.value = false;
      downloadingModelId.value = '';
    }
  }

  Future<void> _downloadDirect(Dio dio, AcousticModel model, Directory dir) async {
    final modelPath = '${dir.path}/${model.id}.tflite';
    final labelsPath = '${dir.path}/${model.id}_labels.txt';

    statusMessage.value = "Downloading Model Engine...";
    
    // Explicitly configure redirection for the binary download
    await dio.download(
      model.downloadUrl, 
      modelPath, 
      options: Options(
        followRedirects: true,
        maxRedirects: 10,
        validateStatus: (status) => status != null && status < 400,
      ),
      onReceiveProgress: (c, t) {
        if (t > 0) downloadProgress.value = (c / t) * 0.9; // Model is 90% of task
      }
    );

    if (model.labelsUrl.isNotEmpty) {
      statusMessage.value = "Downloading Class Mapping...";
      await dio.download(
        model.labelsUrl, 
        labelsPath,
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status != null && status < 400,
        )
      );
    } else {
      // Create a default label file if none provided
      await File(labelsPath).writeAsString("Unclassified");
    }
  }

  Future<void> _downloadAndExtract(Dio dio, AcousticModel model, Directory dir) async {
    final tempPath = '${dir.path}/${model.id}_bundle.tar.gz';
    
    statusMessage.value = "Downloading package...";
    await dio.download(model.downloadUrl, tempPath, onReceiveProgress: (c, t) {
      if (t > 0) downloadProgress.value = (c / t);
    });

    statusMessage.value = "Extracting...";
    final bytes = File(tempPath).readAsBytesSync();
    final gzipBytes = GZipDecoder().decodeBytes(bytes);
    final archive = TarDecoder().decodeBytes(gzipBytes);

    for (final file in archive) {
      if (file.isFile) {
        final data = file.content as List<int>;
        if (file.name.toLowerCase().endsWith('.tflite')) {
          File('${dir.path}/${model.id}.tflite').writeAsBytesSync(data);
        } else if (file.name.toLowerCase().contains('label')) {
          File('${dir.path}/${model.id}_labels.txt').writeAsBytesSync(data);
        }
      }
    }
    await File(tempPath).delete();
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
        duration: const Duration(seconds: 3),
      );
    } catch (_) {}
  }

  Future<void> deleteModel(String id) async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelFile = File('${appDir.path}/models/$id.tflite');
    final labelsFile = File('${appDir.path}/models/${id}_labels.txt');
    
    if (await modelFile.exists()) await modelFile.delete();
    if (await labelsFile.exists()) await labelsFile.delete();
    
    if (_storage.activeModelId == id) {
      _storage.useAdvancedModel = false;
      _storage.activeModelId = 'yamnet';
    }
  }
}