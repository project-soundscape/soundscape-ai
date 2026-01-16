import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart'; // for Colors
import '../../../data/models/recording_model.dart';
import '../../../data/services/appwrite_service.dart';

class DetailsController extends GetxController {
  late Recording recording;
  final player = FlutterSoundPlayer();
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  
  // Waveform Controller
  late PlayerController waveformController;
  
  RxBool isPlaying = false.obs;
  Rx<Duration> currentPosition = Duration.zero.obs;
  Rx<Duration> totalDuration = Duration.zero.obs;
  RxBool isUploading = false.obs;

  @override
  void onInit() {
    super.onInit();
    recording = Get.arguments as Recording;
    waveformController = PlayerController();
    _initPlayer();
    _prepareWaveform();
  }

  Future<void> _prepareWaveform() async {
    try {
      final file = File(recording.path);
      if (await file.exists()) {
         await waveformController.preparePlayer(
           path: recording.path,
           shouldExtractWaveform: true,
           noOfSamples: 100,
           volume: 1.0,
         );
      } else {
        print("Waveform Error: File does not exist at ${recording.path}");
      }
    } catch (e) {
      print("Waveform Error: $e");
    }
  }

  Future<void> _initPlayer() async {
    await player.openPlayer();
    player.setSubscriptionDuration(const Duration(milliseconds: 50));
    player.onProgress?.listen((e) {
      currentPosition.value = e.position;
      totalDuration.value = e.duration;
      if (e.position >= e.duration) {
        isPlaying.value = false;
        currentPosition.value = Duration.zero;
      }
    });
  }

  @override
  void onClose() {
    player.closePlayer();
    waveformController.dispose();
    super.onClose();
  }

  Future<void> togglePlay() async {
    if (isPlaying.value) {
      await player.pausePlayer();
      isPlaying.value = false;
    } else {
      if (player.isPaused) {
        await player.resumePlayer();
      } else {
        await player.startPlayer(fromURI: recording.path, codec: Codec.aacMP4);
      }
      isPlaying.value = true;
    }
  }

  Future<void> submitRecording() async {
    if (isUploading.value) return;
    
    isUploading.value = true;
    try {
      await _appwriteService.uploadRecording(recording);
      // Status update is handled by the service via realtime/local update
    } catch (e) {
      // Error handling is done in service mostly (snackbar)
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> exportAudio() async {
    try {
      await Share.shareXFiles([XFile(recording.path)], text: 'Check out this sound I recorded with Project Soundscape!');
    } catch (e) {
      print("Error sharing: $e");
    }
  }
}