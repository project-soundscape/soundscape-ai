import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/recording_model.dart';
import '../../../data/services/appwrite_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/audio_analysis_service.dart';

class HomeController extends GetxController {
  final FlutterAudioCapture _audioCapture = FlutterAudioCapture();
  final FlutterSoundPlayer player = FlutterSoundPlayer();
  final LocationService _locationService = Get.find<LocationService>();
  
  // File Sink
  RandomAccessFile? _fileRaf;
  int _dataSize = 0;
  
  final StorageService _storageService = Get.find<StorageService>();
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  final AudioAnalysisService _analysisService = Get.find<AudioAnalysisService>();
  
  RxBool isPlaying = false.obs;
  RxBool isPaused = false.obs;
  RxBool isRecording = false.obs;
  RxBool isCompletedRecording = false.obs;
  RxBool isLoading = false.obs;

  Rx<Duration> globalDuration = Duration.zero.obs;
  Duration? totalDuration;
  String recordedFilePath = '';
  Position? _recordingLocation;
  File? _currentFile;
  Timer? _timer;

  // Buffer for YAMNet
  final List<double> _audioBuffer = [];
  
  // Speech Detection Flag
  bool hasSpeechDetected = false;

  @override
  void onInit() {
    super.onInit();
    _initPlayer();
    _preFetchLocation();
    _audioCapture.init(); // Initialize the capture plugin
    
    // Listen to speech confidence
    ever(_analysisService.speechConfidence, (score) {
      if (isRecording.value && score > 0.7) {
        hasSpeechDetected = true;
      }
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    _audioCapture.stop();
    _fileRaf?.close();
    player.closePlayer();
    super.onClose();
  }

  void _initPlayer() async {
    await player.openPlayer();
  }
  
  void _preFetchLocation() async {
     _recordingLocation = await _locationService.getLastKnownLocation();
  }

  Future<void> toggleRecording() async {
    if (isRecording.value) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!await requestPermission(Permission.microphone)) {
         _showError('Microphone permission required');
         return;
      }
      
      // Reset State
      _dataSize = 0;
      _audioBuffer.clear();
      hasSpeechDetected = false;
      globalDuration.value = Duration.zero;
      _analysisService.speechConfidence.value = 0.0;
      _analysisService.topPredictions.clear();

      // Create File
      final dir = await getApplicationDocumentsDirectory();
      recordedFilePath = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';
      _currentFile = File(recordedFilePath);
      
      // Open Random Access File (Write mode truncates if exists, which is fine for new file)
      _fileRaf = await _currentFile!.open(mode: FileMode.write);
      
      // Write Placeholder Header
      _writeWavHeader(0);
      
      // Start Capture
      await _audioCapture.start(
        _onAudioData, 
        (err) => print("Capture Error: $err"), 
        sampleRate: 16000, 
        bufferSize: 3000
      );
      
      isRecording.value = true;
      isCompletedRecording.value = false;
      
      // Manual Timer since we don't have recorder stream for duration
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        globalDuration.value = Duration(seconds: timer.tick);
      });

    } catch (e) {
      print("Error starting recorder: $e");
      _showError('Failed to start recording');
    }
  }

  void _showError(String message, {bool isInfo = false}) {
    if (Get.context != null) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text(message), 
          backgroundColor: isInfo ? Colors.orange : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      Get.snackbar(isInfo ? 'Info' : 'Error', message, 
        backgroundColor: isInfo ? Colors.orange : Colors.red, 
        colorText: Colors.white
      );
    }
  }

  int _callbackCount = 0;

  void _onAudioData(dynamic data) {
    if (!isRecording.value || _fileRaf == null) return;
    
    _callbackCount++;
    
    // FlutterAudioCapture returns Float64List (amplitude -1.0 to 1.0)
    if (data is List<double>) {
      final samples = data; 
      
      // Debug Amplitude
      if (_callbackCount % 100 == 0) {
         double maxAmp = 0;
         for(var s in samples) { if(s.abs() > maxAmp) maxAmp = s.abs(); }
         print("Audio Capture: Chunk #${_callbackCount} | Size: ${samples.length} | Max Amp: $maxAmp");
      }
      
      // 1. Buffer for YAMNet
      _audioBuffer.addAll(samples);
      if (_audioBuffer.length >= AudioAnalysisService.inputSize) {
        _analysisService.analyze(_audioBuffer);
        _audioBuffer.clear();
      }
      
      // 2. Write to WAV File (Convert Float -> Int16)
      // Use ByteData to ensure Little Endian
      final byteData = ByteData(samples.length * 2);
      for (int i = 0; i < samples.length; i++) {
        var s = samples[i];
        if (s > 1.0) s = 1.0;
        if (s < -1.0) s = -1.0;
        final val = (s * 32767).toInt();
        byteData.setInt16(i * 2, val, Endian.little);
      }
      
      final bytes = byteData.buffer.asUint8List();
      _fileRaf!.writeFromSync(bytes);
      _dataSize += bytes.length;
    }
  }

  Future<void> _stopRecording() async {
    // 1. Stop Timer immediately for UI responsiveness
    _timer?.cancel();
    _timer = null;
    
    try {
      // 2. Stop Capture
      await _audioCapture.stop();
    } catch (e) {
      print("Warning: Audio capture stop error: $e");
    }

    try {
      // 3. Finalize File
      if (_fileRaf != null) {
        await _updateWavHeader();
        await _fileRaf!.close();
        _fileRaf = null;
      }
    } catch (e) {
      print("Warning: File close error: $e");
      // Even if file fails, we must stop the recording state
    }
      
    isRecording.value = false;
      
    // Check for Speech
    if (hasSpeechDetected) {
      _showError('Recording Discarded: Speech detected (>70% confidence).', isInfo: true);
      reset(); // Discard
      if (_currentFile != null && await _currentFile!.exists()) {
        await _currentFile!.delete();
      }
      return;
    }
      
    // Validation: Check duration
    if (globalDuration.value.inSeconds < 15) {
      _showError('Recording must be at least 15 seconds', isInfo: true);
    }
      
    isCompletedRecording.value = true;
  }

  Future<void> saveRecording() async {
    if (recordedFilePath.isEmpty) return;
    
    isLoading.value = true;
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
    _appwriteService.uploadRecording(recording);
    
    isLoading.value = false;
    if (Get.context != null) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        const SnackBar(content: Text('Recording saved!'), backgroundColor: Colors.teal),
      );
    }
    reset();
  }

  void discardRecording() async {
    // If currently recording, stop everything first
    if (isRecording.value) {
      _timer?.cancel();
      _timer = null;
      try {
        await _audioCapture.stop();
      } catch (e) {
        print("Error stopping capture during discard: $e");
      }
      try {
        _fileRaf?.close(); // Close active file handle
        _fileRaf = null;
      } catch (e) {
        print("Error closing file during discard: $e");
      }
      isRecording.value = false;
    }

    if (_currentFile != null && await _currentFile!.exists()) {
       try {
         await _currentFile!.delete();
       } catch (e) {
         print("Error deleting discarded file: $e");
       }
    }
    reset();
  }

  Future<void> startPlaying() async {
    await player.startPlayer(fromURI: recordedFilePath);
    isPlaying.value = true;
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
    await player.resumePlayer();
    isPaused.value = false;
    isPlaying.value = true;
  }

  Future<void> stopPlaying() async {
    await player.stopPlayer();
    isPlaying.value = false;
  }

  void reset() {
    isPlaying.value = false;
    isPaused.value = false;
    isRecording.value = false;
    globalDuration.value = Duration.zero;
    recordedFilePath = '';
    isCompletedRecording.value = false;
    hasSpeechDetected = false;
    _analysisService.speechConfidence.value = 0.0;
    _analysisService.topPredictions.clear();
  }

  // WAV Header Utils
  void _writeWavHeader(int dataSize) {
    // 44 bytes placeholder
    _fileRaf?.writeFromSync(Uint8List(44)); 
  }

  Future<void> _updateWavHeader() async {
    if (_fileRaf == null) return;
    
    await _fileRaf!.setPosition(0);
    
    // Header Construction
    final sampleRate = 16000;
    final channels = 1;
    final byteRate = sampleRate * channels * 2;
    final fileSize = _dataSize + 36;
    
    final header = BytesBuilder();
    header.add('RIFF'.codeUnits);
    header.add(_int32(fileSize));
    header.add('WAVE'.codeUnits);
    header.add('fmt '.codeUnits);
    header.add(_int32(16)); // Subchunk1Size
    header.add(_int16(1)); // AudioFormat (PCM)
    header.add(_int16(channels));
    header.add(_int32(sampleRate));
    header.add(_int32(byteRate));
    header.add(_int16(channels * 2)); // BlockAlign
    header.add(_int16(16)); // BitsPerSample
    header.add('data'.codeUnits);
    header.add(_int32(_dataSize));
    
    await _fileRaf!.writeFrom(header.toBytes());
  }
  
  Uint8List _int32(int val) {
    final b = ByteData(4);
    b.setInt32(0, val, Endian.little);
    return b.buffer.asUint8List();
  }
  
  Uint8List _int16(int val) {
    final b = ByteData(2);
    b.setInt16(0, val, Endian.little);
    return b.buffer.asUint8List();
  }
}

Future<bool> requestPermission(Permission permission) async {
  final status = await permission.request();
  return status.isGranted;
}
