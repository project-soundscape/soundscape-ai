import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeController extends GetxController {
  RxBool isPlaying = false.obs;
  RxBool isPaused = false.obs;
  RxBool isRecording = false.obs;
  Duration totalDuration =  Duration.zero;
  Rx<Duration> globalDuration = Duration.zero.obs;
  String recordedFilePath = '';
  RxBool isCompletedRecording = false.obs;
  final player = FlutterSoundPlayer();

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
    isCompletedRecording.value = true;
  }

  void _startRecording() {
    isRecording.value = true;
    globalDuration.value = Duration.zero;

    // Start the recording processR
    Future.microtask(() async {
      final recorder = FlutterSoundRecorder();
      try {
        await recorder.openRecorder();

        final start = DateTime.now();
        recordedFilePath = '${DateTime.now().millisecondsSinceEpoch}.aac';
        await recorder.startRecorder(
          codec: Codec.aacMP4,
          toFile: recordedFilePath,
        );

        while (isRecording.value) {
          await Future.delayed(const Duration(seconds: 1));
          if (!isRecording.value) break;
          globalDuration.value = DateTime.now().difference(start);
          if (DateTime.now().difference(start).inSeconds >= 15) {
            // Auto-stop after 15 seconds
            _stopRecording();
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

  Future<void> startPlaying() async {
    // Logic to start playing the recorded audio
    await player.openPlayer();
    await player.startPlayer(fromURI: recordedFilePath, codec: Codec.aacMP4);
    isPlaying.value = true;
    player.setSubscriptionDuration(const Duration(milliseconds: 50));
    player.onProgress?.listen((e) {
      // Update UI with playback progress if needed
      debugPrint('Playback progress: ${e.position}');
      // set globalDuration.value = e.position;
      globalDuration.value = e.position;
      totalDuration = e.duration;
      if (e.position >= e.duration) {
        stopPlaying();
      }
    });
  }

  Future<void> pausePlaying() async {
    // Logic to pause playing the recorded audio
    await player.pausePlayer();
    isPaused.value = true;
    isPlaying.value = false;
  }

  Future<void> resumePlaying() async {
    // Logic to resume playing the recorded audio
    if (totalDuration.inSeconds == globalDuration.value.inSeconds) {
      // If playback reached the end, restart from beginning
      await stopPlaying();
      await startPlaying();
      return;
    }
    await player.resumePlayer();
    isPaused.value = false;
    isPlaying.value = true;
  }

  Future<void> stopPlaying() async {
    // Logic to stop playing the recorded audio
    await player.stopPlayer();
    await player.closePlayer();
    isPlaying.value = false;
  }

  void reset() {
    isPlaying.value = false;
    isPaused.value = false;
    isRecording.value = false;
    globalDuration.value = Duration.zero;
    recordedFilePath = '';
    isCompletedRecording.value = false;
    totalDuration = Duration.zero;
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
