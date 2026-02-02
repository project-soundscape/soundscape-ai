import 'package:get/get.dart';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../data/services/noise_service.dart';

class NoiseMonitorController extends GetxController {
  final FlutterAudioCapture _audioCapture = FlutterAudioCapture();
  final NoiseService _noiseService = Get.find<NoiseService>();
  
  final isMonitoring = false.obs;
  
  RxDouble get currentDb => _noiseService.currentDb;
  RxDouble get maxDb => _noiseService.maxDb;
  RxDouble get avgDb => _noiseService.avgDb;

  @override
  void onInit() {
    super.onInit();
    _audioCapture.init();
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
      _noiseService.reset();
      await _audioCapture.start(
        _onAudioData,
        (err) => print("Noise Capture Error: $err"),
        sampleRate: 16000,
        bufferSize: 3000
      );
      isMonitoring.value = true;
    } else {
      Get.snackbar('Permission Denied', 'Microphone permission is required for noise monitoring');
    }
  }

  Future<void> stopMonitoring() async {
    await _audioCapture.stop();
    isMonitoring.value = false;
  }

  void _onAudioData(dynamic data) {
    if (!isMonitoring.value) return;
    
    if (data is List<double>) {
      _noiseService.updateFromSamples(data);
    }
  }
}
