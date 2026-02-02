import 'package:get/get.dart';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import '../../../data/services/audio_analysis_service.dart';
import 'package:permission_handler/permission_handler.dart';

class YamnetCheckerController extends GetxController {
  final FlutterAudioCapture _audioCapture = FlutterAudioCapture();
  final AudioAnalysisService _analysisService = Get.find<AudioAnalysisService>();
  
  final isMonitoring = false.obs;
  final List<double> _audioBuffer = [];
  
  final topPredictions = <MapEntry<String, double>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _audioCapture.init();
    
    // Listen to predictions from analysis service
    ever(_analysisService.topPredictions, (List<MapEntry<String, double>> predictions) {
      topPredictions.assignAll(predictions);
    });
  }

  @override
  void onClose() {
    _audioCapture.stop();
    super.onClose();
  }

  Future<void> toggleMonitoring() async {
    if (isMonitoring.value) {
      await stopMonitoring();
    } else {
      await startMonitoring();
    }
  }

  Future<void> startMonitoring() async {
    if (await Permission.microphone.request().isGranted) {
      _audioBuffer.clear();
      await _audioCapture.start(
        _onAudioData,
        (err) => print("Checker Capture Error: $err"),
        sampleRate: _analysisService.currentSampleRate,
        bufferSize: 3000
      );
      isMonitoring.value = true;
    } else {
      Get.snackbar('Permission Denied', 'Microphone permission is required for real-time monitoring');
    }
  }

  Future<void> stopMonitoring() async {
    await _audioCapture.stop();
    isMonitoring.value = false;
    topPredictions.clear();
  }

  void _onAudioData(dynamic data) {
    if (!isMonitoring.value) return;
    
    if (data is List<double>) {
      _audioBuffer.addAll(data);
      if (_audioBuffer.length >= _analysisService.currentInputSize) {
        _analysisService.analyze(_audioBuffer);
        _audioBuffer.clear();
      }
    }
  }
}
