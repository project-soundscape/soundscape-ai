import 'package:get/get.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeController extends GetxController {
  RxBool isRecording = false.obs;
  Rx<Duration> recordingDuration = Duration.zero.obs;

  final count = 0.obs;
  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void increment() => count.value++;

  Future<void> toggleRecording() async {
    // Logic to start or stop recording
    if (isRecording.value) {
      _stopRecording();
    } else {
      bool granted = await requestPermission(Permission.microphone);
      if (!granted) return;
      _startRecording();
    }
  }

  void _stopRecording() {
    isRecording.value = false;
  }

  void _startRecording() {
    isRecording.value = true;
    recordingDuration.value = Duration.zero;

    // Start the recording processR
    Future.microtask(() async {
      final recorder = FlutterSoundRecorder();
      try {
        await recorder.openRecorder();

        final start = DateTime.now();
        await recorder.startRecorder(
          codec: Codec.aacMP4,
          toFile: 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a',
        );

        while (isRecording.value) {
          await Future.delayed(const Duration(seconds: 1));
          if (!isRecording.value) break;
          recordingDuration.value = DateTime.now().difference(start);
          if (DateTime.now().difference(start).inSeconds >= 15) {
            // Auto-stop after 15 seconds
            isRecording.value = false;
            break;
          }
        }
      } finally {
        try {
          await recorder.stopRecorder();
        } catch (_) {}
        try {
          await recorder.closeRecorder();
        } catch (_) {}
      }
    });
  }
}

Future<bool> requestPermission(Permission permission) async {
  final status = await permission.request();

  if (status.isGranted) {
    // Permission is granted
    return true;
  } else if (status.isPermanentlyDenied) {
    // Permission is permanently denied, open app settings
    await openAppSettings();
    return false;
  } else {
    // Permission is denied (but not permanently)
    return false;
  }
}
