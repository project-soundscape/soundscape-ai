import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class AudioAnalysisService extends GetxService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  
  // YAMNet specific
  static const int sampleRate = 16000;
  static const int inputSize = 15600; // 0.975s
  
  final RxDouble speechConfidence = 0.0.obs;
  final RxString topEvent = "Silence".obs;
  final RxList<MapEntry<String, double>> topPredictions = <MapEntry<String, double>>[].obs;
  
  bool get isReady => _interpreter != null && _labels.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      final options = InterpreterOptions();
      // On Android, use NNAPI if available? For now, CPU is safer.
      // options.addDelegate(NnApiDelegate());
      
      print("AudioAnalysis: Loading YAMNet model...");
      _interpreter = await Interpreter.fromAsset('assets/tflite/yamnet.tflite', options: options);
      print("AudioAnalysis: Model Loaded. Input shape: ${_interpreter?.getInputTensor(0).shape}");
      
      await _loadLabels();
    } catch (e) {
      print("AudioAnalysis: Error loading YAMNet: $e");
    }
  }

  Future<void> _loadLabels() async {
    try {
      final csvData = await rootBundle.loadString('assets/tflite/yamnet_class_map.csv');
      final lines = csvData.split('\n');
      
      _labels = List.filled(521, "Unknown");
      
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().isEmpty) continue;
        
        final parts = line.split(',');
        if (parts.length >= 3) {
            final index = int.tryParse(parts[0]);
            String name = parts.sublist(2).join(',');
            if (name.startsWith('"') && name.endsWith('"')) {
              name = name.substring(1, name.length - 1);
            }
            
            if (index != null && index < 521) {
              _labels[index] = name.trim();
            }
        }
      }
      print("AudioAnalysis: Labels loaded. Count: ${_labels.length}. Label[0]: ${_labels[0]}");
    } catch (e) {
      print("AudioAnalysis: Error loading labels: $e");
    }
  }
  
  // ... (existing code)

  void analyze(List<double> buffer) {
    if (_interpreter == null) return;
    if (buffer.length < inputSize) return;

    final input = Float32List.fromList(buffer.sublist(0, inputSize));
    var output = List<double>.filled(521, 0).reshape([1, 521]);
    
    try {
      _interpreter!.run(input, output);
      
      // 1. Update Speech Confidence
      if (_labels.isNotEmpty && _labels[0] == 'Speech') {
         speechConfidence.value = output[0][0];
      }
      
      // 2. Get Top 5 Predictions
      // Create a list of (index, score)
      List<MapEntry<int, double>> scores = [];
      for(int i=0; i<521; i++) {
        scores.add(MapEntry(i, output[0][i]));
      }
      
      // Sort descending
      scores.sort((a, b) => b.value.compareTo(a.value));
      
      // Take top 5
      final top5 = scores.take(5).map((e) {
        final label = _labels.length > e.key ? _labels[e.key] : "Unknown";
        return MapEntry(label, e.value);
      }).toList();
      
      topPredictions.assignAll(top5);
      
      // Update top event for debug
      if (top5.isNotEmpty) {
        topEvent.value = "${top5.first.key} (${(top5.first.value*100).toInt()}%)";
      }

    } catch (e) {
      print("AudioAnalysis: Inference Failed: $e");
    }
  }
}
