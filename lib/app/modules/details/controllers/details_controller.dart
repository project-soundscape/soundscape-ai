import 'dart:io';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart'; 
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/recording_model.dart';
import '../../../data/services/appwrite_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/wiki_service.dart';
import '../../../data/services/audio_analysis_service.dart';

class DetailsController extends GetxController {
  late Recording recording;
  final player = FlutterSoundPlayer();
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  final AudioAnalysisService _analysisService = Get.find<AudioAnalysisService>();
  final WikiService _wikiService = Get.put(WikiService());
  
  // Waveform Controller
  late PlayerController waveformController;
  
  RxBool isPlaying = false.obs;
  Rx<Duration> currentPosition = Duration.zero.obs;
  Rx<Duration> totalDuration = Duration.zero.obs;
  Rx<Duration> remainingTime = Duration.zero.obs;
  RxBool isUploading = false.obs;
  
  String? localFilePath;
  RandomAccessFile? _audioFileHandle;
  Duration _lastAnalysisTime = const Duration(seconds: -1);
  
  // Species Info
  final Rxn<Map<String, dynamic>> speciesData = Rxn();
  final RxBool isLoadingWiki = false.obs;
  final RxBool isScanning = false.obs;
  final RxDouble scanProgress = 0.0.obs;
  final scanResults = <String, double>{}.obs;

  @override
  void onInit() {
    super.onInit();
    recording = Get.arguments as Recording;
    waveformController = PlayerController();
    _prepareFile();
    
    if (recording.commonName != null) {
      fetchSpeciesInfo(recording.commonName!);
    }
  }
  
  Future<void> fetchSpeciesInfo(String scientificName) async {
    isLoadingWiki.value = true;
    final data = await _wikiService.getBirdInfo(scientificName);
    if (data != null) {
      speciesData.value = data;
    }
    isLoadingWiki.value = false;
  }

  Future<void> launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar("Error", "Could not launch $url");
    }
  }

  Future<void> openEBird(String scientificName) async {
    final query = Uri.encodeComponent(scientificName);
    final url = 'https://ebird.org/species/search?query=$query';
    await launchURL(url);
  }
  
  Future<void> _prepareFile() async {
    if (recording.path.startsWith('http')) {
      try {
        localFilePath = await _appwriteService.downloadRecordingFile(recording.path);
        
        // Save the local path back to the recording object and update storage
        // This makes it available offline immediately for next time
        if (localFilePath != null) {
          recording.path = localFilePath!;
          Get.find<StorageService>().updateRecording(recording);
        }
      } catch (e) {
        print("Error downloading file: $e");
        Get.snackbar("Error", "Could not load audio file");
      }
    } else {
      localFilePath = recording.path;
    }
    
    if (localFilePath != null) {
      await _initPlayer();
      await _prepareWaveform();
      // Open file handle for analysis if it's a WAV
      if (localFilePath!.endsWith('.wav')) {
        try {
          _audioFileHandle = await File(localFilePath!).open(mode: FileMode.read);
          print("Details: Opened file handle for analysis: $localFilePath");
          
          // Pre-analyze the first chunk immediately so the UI is populated ASAP
          await _analyzeChunkAt(Duration.zero);
        } catch (e) {
          print("Details: Error opening file handle: $e");
        }
      }
    }
  }

  Future<void> _prepareWaveform() async {
    if (localFilePath == null) return;
    try {
      final file = File(localFilePath!);
      if (await file.exists()) {
         await waveformController.preparePlayer(
           path: localFilePath!,
           shouldExtractWaveform: true,
           noOfSamples: 100,
           volume: 1.0,
         );
      }
    } catch (e) {
      print("Waveform Error: $e");
    }
  }

  Future<void> _initPlayer() async {
    await player.openPlayer();
    player.setSubscriptionDuration(const Duration(milliseconds: 100));
    player.onProgress?.listen((e) {
      currentPosition.value = e.position;
      totalDuration.value = e.duration;
      remainingTime.value = e.duration - e.position;
      
      // Perform YAMNet analysis during playback
      _analyzeChunkAt(e.position);

      if (e.position >= e.duration) {
        stopPlayer();
      }
    });
  }

  Future<void> stopPlayer() async {
    await player.stopPlayer();
    isPlaying.value = false;
    currentPosition.value = Duration.zero;
    remainingTime.value = totalDuration.value;
    _lastAnalysisTime = const Duration(seconds: -1); // Reset throttle
    // Note: topPredictions are intentionally NOT cleared here 
    // so users can see the last analysis results.
  }

  Future<void> _analyzeChunkAt(Duration position) async {
    if (_audioFileHandle == null) return;
    
    // Throttle: Only analyze if we've moved at least 1 second since last analysis
    final int diff = (position.inMilliseconds - _lastAnalysisTime.inMilliseconds).abs();
    if (diff < 1000) return; 

    if (!_analysisService.isReady) {
      print("Details: Analysis service not ready yet");
      return;
    }
    
    try {
      _lastAnalysisTime = position; // Update last analysis time
      
      // Dynamic Sample Rate & Input Size
      final int sampleRate = _analysisService.currentSampleRate;
      const int headerSize = 44;
      final int startSample = (position.inMilliseconds * sampleRate / 1000).toInt();
      final int startByte = headerSize + (startSample * 2);
      
      // Read currentInputSize samples
      final int bytesToRead = _analysisService.currentInputSize * 2;
      
      final int fileLength = await _audioFileHandle!.length();
      if (startByte + bytesToRead > fileLength) {
        return;
      }

      await _audioFileHandle!.setPosition(startByte);
      final Uint8List bytes = await _audioFileHandle!.read(bytesToRead);
      
      if (bytes.length < bytesToRead) return;
      
      final List<double> samples = [];
      final ByteData byteData = ByteData.sublistView(bytes);
      for (int i = 0; i < bytes.length; i += 2) {
        final int val = byteData.getInt16(i, Endian.little);
        samples.add(val / 32767.0);
      }
      
      print("Details: Analyzing segment at ${position.inSeconds}s using ${_analysisService.isPerch ? 'BirdNET' : 'YAMNet'}");
      _analysisService.analyze(samples);
    } catch (e) {
      print("Details: Chunk analysis error: $e");
    }
  }

  Future<void> scanFullFile() async {
    if (_audioFileHandle == null || isScanning.value) return;
    
    isScanning.value = true;
    scanProgress.value = 0.0;
    scanResults.clear();
    
    try {
      final int sampleRate = _analysisService.currentSampleRate;
      final int inputSize = _analysisService.currentInputSize;
      final int bytesPerWindow = inputSize * 2;
      const int headerSize = 44;
      
      final int fileLength = await _audioFileHandle!.length();
      final int dataLength = fileLength - headerSize;
      final int totalSteps = (dataLength / bytesPerWindow).floor();
      
      if (totalSteps <= 0) {
        Get.snackbar("Error", "Clip is too short for deep scanning");
        return;
      }

      for (int i = 0; i < totalSteps; i++) {
        final int startByte = headerSize + (i * bytesPerWindow);
        await _audioFileHandle!.setPosition(startByte);
        final Uint8List bytes = await _audioFileHandle!.read(bytesPerWindow);
        
        if (bytes.length < bytesPerWindow) break;
        
        final List<double> samples = [];
        final ByteData byteData = ByteData.sublistView(bytes);
        for (int j = 0; j < bytes.length; j += 2) {
          samples.add(byteData.getInt16(j, Endian.little) / 32767.0);
        }
        
        // Analyze manually to avoid clearing topPredictions
        _analysisService.analyze(samples);
        
        // Aggregate highest scores
        for (var entry in _analysisService.topPredictions) {
          if (entry.value > (scanResults[entry.key] ?? 0)) {
            scanResults[entry.key] = entry.value;
          }
        }
        
        scanProgress.value = (i + 1) / totalSteps;
        // Small yield to keep UI responsive
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      Get.snackbar("Scan Complete", "Detected ${scanResults.length} unique sound classes.", 
        backgroundColor: Colors.teal, colorText: Colors.white);
        
    } catch (e) {
      print("Full Scan Error: $e");
      Get.snackbar("Error", "Failed to complete acoustic scan.");
    } finally {
      isScanning.value = false;
    }
  }

  @override
  void onClose() {
    player.closePlayer();
    waveformController.dispose();
    _audioFileHandle?.close();
    _analysisService.topPredictions.clear();
    super.onClose();
  }

  Future<void> togglePlay() async {
    try {
      if (isPlaying.value) {
        if (player.isPlaying) {
          await player.pausePlayer();
        }
        isPlaying.value = false;
      } else {
        if (player.isPaused) {
          await player.resumePlayer();
        } else {
          // Use default codec detection instead of forcing aacMP4
          await player.startPlayer(fromURI: localFilePath);
        }
        isPlaying.value = true;
      }
    } catch (e) {
      Get.snackbar("Error", "Playback error: $e");
      isPlaying.value = false;
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
    if (localFilePath == null) return;
    try {
      await Share.shareXFiles([XFile(localFilePath!)], text: 'Check out this sound I recorded with Project Soundscape!');
    } catch (e) {
      print("Error sharing: $e");
    }
  }
}