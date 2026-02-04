import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';
import 'noise_service.dart';

class AudioAnalysisService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();
  final NoiseService _noiseService = Get.find<NoiseService>();
  
  Interpreter? _interpreter;
  Interpreter? _yamnetSpeechInterpreter; // Dedicated for speech detection
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
    _loadSpeechDetector();
    _loadActiveModel();
  }

  Future<void> _loadSpeechDetector() async {
    try {
      print("AudioAnalysis: Loading YAMNet for speech detection...");
      _yamnetSpeechInterpreter = await Interpreter.fromAsset('assets/tflite/yamnet.tflite');
    } catch (e) {
      print("AudioAnalysis: Speech detector load error: $e");
    }
  }

  Future<void> reloadModel() async {
    await _loadActiveModel();
  }

  Future<void> _loadActiveModel() async {
    isModelLoading.value = true;
    try {
      final modelId = _storage.activeModelId;
      if (modelId == 'yamnet') {
        await _loadYamnetModel();
      } else {
        await _loadExternalModel(modelId);
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

  Future<void> _loadExternalModel(String id) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelFile = File('${appDir.path}/models/$id.tflite');
      final labelsFile = File('${appDir.path}/models/${id}_labels.txt');
      
      if (!await modelFile.exists()) {
        print("AudioAnalysis: Model $id not found locally. Falling back.");
        _storage.activeModelId = 'yamnet';
        return _loadYamnetModel();
      }

      print("AudioAnalysis: Loading external model $id...");
      _interpreter = Interpreter.fromFile(modelFile);
      
      // Auto-detect config from tensor
      final inputTensor = _interpreter!.getInputTensor(0);
      currentInputSize = inputTensor.shape.last;
      
      // BirdNET variants typically use 48kHz, others might use 16kHz
      currentSampleRate = id.contains('birdnet') ? 48000 : 16000;
      isPerch = id.contains('birdnet'); 

      if (await labelsFile.exists()) {
        final lines = await labelsFile.readAsLines();
        _labels = lines.map((l) => l.contains('_') ? l.split('_').last.trim() : l.trim()).toList();
      }
      
      numClasses = _labels.length;
      print("AudioAnalysis: External Model $id Ready. Classes: $numClasses");
    } catch (e) {
      print("AudioAnalysis: Error loading $id: $e. Falling back.");
      _storage.activeModelId = 'yamnet';
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

  // Helper for running inference
  List<double> _runInference(List<double> buffer) {
    final input = Float32List.fromList(buffer).reshape([1, currentInputSize]);
    var output = List<double>.filled(numClasses, 0).reshape([1, numClasses]);
    _interpreter!.run(input, output);
    return output[0];
  }

  // Pre-processing for denoising
  List<double> _applyDenoise(List<double> input) {
     // 1. RMS & Auto-Gain
     double sum = 0;
     for(var s in input) {
       sum += s*s;
     }
     double rms = sqrt(sum / input.length);
     
     // Target RMS ~ 0.1 (-20dB). Max Gain 5x.
     double gain = 1.0;
     if (rms > 0.001) {
       gain = (0.1 / rms).clamp(1.0, 5.0);
     }
     
     // 2. Noise Gate
     double noiseFloorDb = _noiseService.avgDb.value;
     if (noiseFloorDb == 0) noiseFloorDb = 40; // Default floor
     
     // Threshold: Slightly below average noise
     double threshold = pow(10, (noiseFloorDb - 105) / 20).toDouble();
     
     return input.map((s) {
       double val = s * gain;
       if (val.abs() < threshold) return 0.0;
       return val;
     }).toList();
  }

  void analyze(List<double> buffer) {
    if (_interpreter == null || _labels.isEmpty) return;
    if (buffer.length < currentInputSize) return;

    try {
      // 1. Initial Inference
      var output = _runInference(buffer.sublist(0, currentInputSize));
      
      // 2. Run Background Speech Detection (Always YAMNet)
      if (isPerch && _yamnetSpeechInterpreter != null) {
        // Downsample from 48kHz to 16kHz (every 3rd sample)
        final List<double> downsampled = [];
        for (int i = 0; i < buffer.length && downsampled.length < yamnetInputSize; i += 3) {
          downsampled.add(buffer[i]);
        }
        
        if (downsampled.length == yamnetInputSize) {
          final speechInput = Float32List.fromList(downsampled).reshape([1, yamnetInputSize]);
          var speechOutput = List<double>.filled(521, 0).reshape([1, 521]);
          _yamnetSpeechInterpreter!.run(speechInput, speechOutput);
          // Label index 0 in YAMNet is 'Speech'
          speechConfidence.value = speechOutput[0][0];
        }
      } else if (!isPerch) {
        // Main model is already YAMNet
        speechConfidence.value = output[0];
      }
      
      // 3. Check if we should Enhance (Denoise + Re-run)
      int topIndex = -1;
      double topScore = -1.0;
      for(int i=0; i<output.length; i++) {
        if (output[i] > topScore) {
          topScore = output[i];
          topIndex = i;
        }
      }
      String topLabel = (topIndex >= 0 && topIndex < _labels.length) ? _labels[topIndex] : "Unknown";

      // If confidence > 0.6 and not Silence/Speech, try to enhance
      if (topScore > 0.6 && topLabel != 'Silence' && topLabel != 'Speech') {
         final processed = _applyDenoise(buffer.sublist(0, currentInputSize));
         final output2 = _runInference(processed);
         
         double topScore2 = 0;
         for(var s in output2) {
           if(s > topScore2) topScore2 = s;
         }
         
         if (topScore2 > topScore) {
            output = output2; // Use improved result
         }
      }
      
      // 4. Update Predictions
      List<MapEntry<int, double>> scores = [];
      for(int i=0; i<numClasses; i++) {
        scores.add(MapEntry(i, output[i]));
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
