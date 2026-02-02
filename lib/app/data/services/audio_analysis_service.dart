import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';

class AudioAnalysisService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();
  
  Interpreter? _interpreter;
  List<String> _labels = [];
  
  // Model Config
  int currentSampleRate = 16000;
  int currentInputSize = 15600; // Default for YAMNet
  int numClasses = 521;
  bool isPerch = false;
  
  // YAMNet defaults
  static const int yamnetSampleRate = 16000;
  static const int yamnetInputSize = 15600; 
  static const int inputSize = 15600; // For backward compatibility
  
  // BirdNET defaults
  static const int birdnetSampleRate = 48000;
  static const int birdnetInputSize = 144000; // 3 seconds at 48kHz
  
  final RxDouble speechConfidence = 0.0.obs;
  final RxString topEvent = "Silence".obs;
  final RxList<MapEntry<String, double>> topPredictions = <MapEntry<String, double>>[].obs;
  final RxBool isModelLoading = false.obs;
  
  bool get isReady => _interpreter != null && _labels.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _loadActiveModel();
  }

  Future<void> reloadModel() async {
    await _loadActiveModel();
  }

  Future<void> _loadActiveModel() async {
    isModelLoading.value = true;
    try {
      if (_storage.useAdvancedModel) {
        await _loadBirdNetModel();
      } else {
        await _loadYamnetModel();
      }
    } finally {
      isModelLoading.value = false;
    }
  }

  Future<void> _loadYamnetModel() async {
    try {
      print("AudioAnalysis: Loading YAMNet model...");
      final options = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset('assets/tflite/yamnet.tflite', options: options);
      
      currentSampleRate = yamnetSampleRate;
      currentInputSize = yamnetInputSize;
      numClasses = 521;
      isPerch = false;

      await _loadYamnetLabels();
      print("AudioAnalysis: YAMNet Ready.");
    } catch (e) {
      print("AudioAnalysis: Error loading YAMNet: $e");
    }
  }

  Future<void> _loadBirdNetModel() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelFile = File('${appDir.path}/models/birdnet.tflite');
      
      if (!await modelFile.exists()) {
        print("AudioAnalysis: BirdNET model file not found. Falling back to YAMNet.");
        _storage.useAdvancedModel = false;
        return _loadYamnetModel();
      }

      print("AudioAnalysis: Loading BirdNET model from ${modelFile.path}...");
      _interpreter = Interpreter.fromFile(modelFile);
      
      currentSampleRate = birdnetSampleRate;
      currentInputSize = birdnetInputSize;
      isPerch = true; // Still using this flag for 'advanced model' logic

      await _loadBirdNetLabels();
      numClasses = _labels.length;
      print("AudioAnalysis: BirdNET Ready. Classes: $numClasses");
    } catch (e) {
      print("AudioAnalysis: Error loading BirdNET: $e. Falling back.");
      _storage.useAdvancedModel = false;
      await _loadYamnetModel();
    }
  }

  Future<void> _loadYamnetLabels() async {
    try {
      final csvData = await rootBundle.loadString('assets/tflite/yamnet_class_map.csv');
      final lines = csvData.split('\n');
      _labels = List.filled(521, "Unknown");
      for (var i = 1; i < lines.length; i++) {
        final parts = lines[i].split(',');
        if (parts.length >= 3) {
            final index = int.tryParse(parts[0]);
            String name = parts.sublist(2).join(',').replaceAll('"', '').trim();
            if (index != null && index < 521) _labels[index] = name;
        }
      }
    } catch (e) {
      print("Labels Error: $e");
    }
  }

  Future<void> _loadBirdNetLabels() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final labelsFile = File('${appDir.path}/models/birdnet_labels.txt');
      if (await labelsFile.exists()) {
        final lines = await labelsFile.readAsLines();
        _labels = lines.map((l) {
          // BirdNET-Analyzer v2.4 usually uses "Scientific Name_Common Name"
          if (l.contains('_')) {
            return l.split('_').last.trim();
          }
          // Some versions use "Scientific Name Common Name" (tab or multiple spaces)
          return l.trim();
        }).toList();
      }
    } catch (e) {
      print("BirdNET Labels Error: $e");
    }
  }

  void analyze(List<double> buffer) {
    if (_interpreter == null || _labels.isEmpty) return;
    if (buffer.length < currentInputSize) return;

    final input = Float32List.fromList(buffer.sublist(0, currentInputSize));
    var output = List<double>.filled(numClasses, 0).reshape([1, numClasses]);
    
    try {
      _interpreter!.run(input, output);
      
      if (!isPerch && _labels[0] == 'Speech') {
         speechConfidence.value = output[0][0];
      }
      
      List<MapEntry<int, double>> scores = [];
      for(int i=0; i<numClasses; i++) {
        scores.add(MapEntry(i, output[0][i]));
      }
      
      scores.sort((a, b) => b.value.compareTo(a.value));
      
      final top5 = scores.take(5).map((e) {
        final label = _labels.length > e.key ? _labels[e.key] : "Unknown";
        return MapEntry(label, e.value);
      }).toList();
      
      topPredictions.assignAll(top5);
      if (top5.isNotEmpty) {
        topEvent.value = "${top5.first.key} (${(top5.first.value*100).toInt()}%)";
      }
    } catch (e) {
      print("AudioAnalysis: Inference Failed: $e");
    }
  }
}
