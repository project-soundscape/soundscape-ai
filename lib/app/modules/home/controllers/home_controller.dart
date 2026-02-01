import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import '../../../data/models/recording_model.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/appwrite_service.dart';

class HomeController extends GetxController {
  final LocationService _locationService = Get.find<LocationService>();
  final StorageService _storageService = Get.find<StorageService>();
  final AppwriteService _appwriteService = Get.find<AppwriteService>();

  RxBool isPlaying = false.obs;
  RxBool isPaused = false.obs;
  RxBool isRecording = false.obs;
  RxBool isLoading = false.obs;
  
  Duration totalDuration = Duration.zero;
  Rx<Duration> globalDuration = Duration.zero.obs;
  String recordedFilePath = '';
  RxBool isCompletedRecording = false.obs;
  
  final player = FlutterSoundPlayer();
  final recorder = FlutterSoundRecorder();
  StreamSubscription? _recorderSubscription;

  Position? _recordingLocation;

  @override
  void onInit() {
    super.onInit();
    _initRecorder();
    _preFetchLocation();
  }

  Future<void> _initRecorder() async {
    await recorder.openRecorder();
    recorder.setSubscriptionDuration(const Duration(milliseconds: 100));
  }

  Future<void> _preFetchLocation() async {
    try {
      _recordingLocation = await _locationService.getLastKnownLocation();
    } catch (_) {}
  }

  @override
  void onClose() {
    player.closePlayer();
    recorder.closeRecorder();
    _recorderSubscription?.cancel();
    super.onClose();
  }

  Future<void> toggleRecording() async {
    if (isRecording.value) {
      if (globalDuration.value.inSeconds < 15) {
        Get.snackbar('Too Short', 'Recording must be at least 15 seconds');
        return;
      }
      await _stopRecording();
    } else {
      bool granted = await requestPermission(Permission.microphone);
      if (!granted) return;
      
      bool locGranted = await requestPermission(Permission.location);
      if (locGranted) {
        // Try to get fresh location just before/during recording
        _locationService.getCurrentLocation().then((pos) {
          _recordingLocation = pos;
        }).catchError((e) {
          print("Location error: $e");
          return null;
        });
      }
      
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      recordedFilePath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
      
      await recorder.startRecorder(
        codec: Codec.aacMP4,
        toFile: recordedFilePath,
      );
      
      isRecording.value = true;
      isCompletedRecording.value = false;
      globalDuration.value = Duration.zero;

      _recorderSubscription = recorder.onProgress?.listen((e) {
        globalDuration.value = e.duration;
        if (e.duration.inSeconds >= 60) {
          _stopRecording();
        }
      });
    } catch (e) {
      print("Error starting recorder: $e");
      Get.snackbar('Error', 'Failed to start recording');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await recorder.stopRecorder();
      _recorderSubscription?.cancel();
      isRecording.value = false;
      isCompletedRecording.value = true;
    } catch (e) {
      print("Error stopping recorder: $e");
    }
  }

  Future<void> saveRecording() async {
    if (recordedFilePath.isEmpty) return;
    
    isLoading.value = true;

    // If location is still null, try one last time to get last known
    _recordingLocation ??= await _locationService.getLastKnownLocation();

    final recording = Recording(
      id: const Uuid().v4(),
      path: recordedFilePath,
      timestamp: DateTime.now(),
      duration: globalDuration.value,
      latitude: _recordingLocation?.latitude,
      longitude: _recordingLocation?.longitude,
      status: 'pending',
    );

    await _storageService.saveRecording(recording);
    
    // Auto-upload in background
    _appwriteService.uploadRecording(recording);
    
    isLoading.value = false;
    if (Get.context != null) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        const SnackBar(content: Text('Recording saved to library!'), backgroundColor: Colors.teal),
      );
    }
    reset();
  }

  void discardRecording() {
    reset();
  }

  // ... Playback methods same as before ...
  Future<void> startPlaying() async {
    await player.openPlayer();
    await player.startPlayer(fromURI: recordedFilePath, codec: Codec.aacMP4);
    isPlaying.value = true;
    player.setSubscriptionDuration(const Duration(milliseconds: 50));
    player.onProgress?.listen((e) {
      globalDuration.value = e.position;
      totalDuration = e.duration;
      if (e.position >= e.duration) {
        stopPlaying();
      }
    });
  }

  Future<void> pausePlaying() async {
    await player.pausePlayer();
    isPaused.value = true;
    isPlaying.value = false;
  }

  Future<void> resumePlaying() async {
    if (totalDuration.inSeconds == globalDuration.value.inSeconds) {
      await stopPlaying();
      await startPlaying();
      return;
    }
    await player.resumePlayer();
    isPaused.value = false;
    isPlaying.value = true;
  }

  Future<void> stopPlaying() async {
    await player.stopPlayer();
    await player.closePlayer();
    isPlaying.value = false;
  }

  void reset() {
    isPlaying.value = false;
    isPaused.value = false;
    isRecording.value = false;
    player.closePlayer();
    globalDuration.value = Duration.zero;
    recordedFilePath = '';
    isCompletedRecording.value = false;
    totalDuration = Duration.zero;
    _recordingLocation = null;
  }
}

Future<bool> requestPermission(Permission permission) async {
  final status = await permission.request();
  return status.isGranted;
}