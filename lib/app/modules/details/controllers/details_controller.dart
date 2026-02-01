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
  RxBool isUploading = false.obs;
  
  String? localFilePath;
  RandomAccessFile? _audioFileHandle;
  
  // Species Info
  final Rxn<Map<String, dynamic>> speciesData = Rxn();
  final RxBool isLoadingWiki = false.obs;

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
      
      // Perform YAMNet analysis during playback
      _analyzeChunkAt(e.position);

      if (e.position >= e.duration) {
        isPlaying.value = false;
        currentPosition.value = Duration.zero;
        _analysisService.topPredictions.clear();
      }
    });
  }

  Future<void> _analyzeChunkAt(Duration position) async {
    if (_audioFileHandle == null) return;
    
    try {
      // 16kHz, 16bit, Mono WAV
      // Header is 44 bytes
      // Sample size is 2 bytes
      // Position in samples = position.inSeconds * 16000
      // Position in bytes = 44 + (samples * 2)
      
      const int sampleRate = 16000;
      const int headerSize = 44;
      final int startSample = (position.inMilliseconds * sampleRate / 1000).toInt();
      final int startByte = headerSize + (startSample * 2);
      
      // Read inputSize samples (15600)
      final int bytesToRead = AudioAnalysisService.inputSize * 2;
      
      await _audioFileHandle!.setPosition(startByte);
      final Uint8List bytes = await _audioFileHandle!.read(bytesToRead);
      
      if (bytes.length < bytesToRead) return;
      
      // Convert bytes (Int16 LE) to List<double>
      final List<double> samples = [];
      final ByteData byteData = ByteData.sublistView(bytes);
      for (int i = 0; i < bytes.length; i += 2) {
        final int val = byteData.getInt16(i, Endian.little);
        samples.add(val / 32767.0);
      }
      
      _analysisService.analyze(samples);
    } catch (e) {
      // Silent fail for analysis
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
          await player.startPlayer(fromURI: localFilePath, codec: Codec.aacMP4);
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