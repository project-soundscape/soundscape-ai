import 'dart:io';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart'; 
import 'package:url_launcher/url_launcher.dart';
import 'package:appwrite/appwrite.dart';
import 'package:path/path.dart' as p;
import '../../../data/models/recording_model.dart';
import '../../../data/services/appwrite_service.dart';
import '../../../data/services/evolution_api_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/model_download_service.dart';
import '../../../data/services/wiki_service.dart';
import '../../../data/services/audio_analysis_service.dart';
import '../../../data/services/connectivity_service.dart';
import '../../../utils/datetime_extensions.dart';

class DetailsController extends GetxController {
  late Recording recording;
  final player = FlutterSoundPlayer();
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  final AudioAnalysisService _analysisService = Get.find<AudioAnalysisService>();
  final WikiService _wikiService = Get.put(WikiService());
  final StorageService _storageService = Get.find<StorageService>();
  final ModelDownloadService _modelDownloadService = Get.find<ModelDownloadService>();
  final ConnectivityService _connectivityService = Get.find<ConnectivityService>();
  
  // Waveform Controller
  late PlayerController waveformController;
  
  RxBool isPlaying = false.obs;
  Rx<Duration> currentPosition = Duration.zero.obs;
  Rx<Duration> totalDuration = Duration.zero.obs;
  Rx<Duration> remainingTime = Duration.zero.obs;
  RxBool isUploading = false.obs;
  RxBool isSentToResearch = false.obs;
  final RxDouble researchProgress = 0.0.obs;
  
  // Connectivity
  RxBool get isOnline => _connectivityService.isConnectedRx;
  
  // Model State
  final RxString activeModelId = 'yamnet'.obs;
  final RxSet<String> downloadedModels = <String>{}.obs;
  
  String? localFilePath;
  RandomAccessFile? _audioFileHandle;
  Duration _lastAnalysisTime = const Duration(seconds: -1);
  
  // Species Info
  final RxMap<String, Map<String, dynamic>> speciesData = <String, Map<String, dynamic>>{}.obs;
  final RxBool isLoadingWiki = false.obs;
  final RxBool isScanning = false.obs;
  final RxDouble scanProgress = 0.0.obs;
  final scanResults = <String, double>{}.obs;
  final timelineEvents = <Map<String, dynamic>>[].obs;
  
  // Language Support
  final RxString selectedLanguage = 'en'.obs;
  final List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'ml', 'name': 'മലയാളം'},
    {'code': 'hi', 'name': 'हिन्दी'},
  ];

  // Track requested species to prevent duplicate fetches
  final Set<String> _requestedSpecies = {};

  @override
  void onInit() async {
    super.onInit();
    recording = Get.arguments as Recording;
    isSentToResearch.value = recording.researchRequested;
    activeModelId.value = _storageService.activeModelId;
    _checkDownloadedModels();
    waveformController = PlayerController();
    _prepareFile();
    
    // If processed but no predictions, fetch from Appwrite
    if (recording.status == 'processed' && (recording.predictions == null || recording.predictions!.isEmpty)) {
      await _fetchRemoteDetections();
    }
    
    // No eager fetching here anymore. View calls resolveSpeciesInfo
  }

  Future<void> _checkDownloadedModels() async {
    for (var model in _modelDownloadService.availableModels) {
      if (await _modelDownloadService.isModelDownloaded(model.id)) {
        downloadedModels.add(model.id);
      }
    }
  }

  Future<void> switchModel(String id) async {
    if (activeModelId.value == id) return;

    if (id != 'yamnet' && !downloadedModels.contains(id)) {
      final model = _modelDownloadService.availableModels.firstWhere((m) => m.id == id);
      await _modelDownloadService.downloadAcousticModel(model);
      await _checkDownloadedModels();
      if (!downloadedModels.contains(id)) return;
    }

    _storageService.activeModelId = id;
    activeModelId.value = id;
    await _analysisService.reloadModel();
    
    // If we have a file handle and are not currently playing, 
    // re-analyze current position to show updated results
    if (_audioFileHandle != null && !isPlaying.value) {
      _lastAnalysisTime = const Duration(seconds: -1); // Force re-analysis
      await _analyzeChunkAt(currentPosition.value);
    }
    
    Get.snackbar(
      'Model Switched',
      'Using ${id == 'yamnet' ? 'YAMNet' : _modelDownloadService.availableModels.firstWhere((m) => m.id == id).name}',
      backgroundColor: Colors.teal,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  List<AcousticModel> get availableModels => _modelDownloadService.availableModels;

  // Called by View to lazily load data
  void resolveSpeciesInfo(String name) {
    if (name.isEmpty) return;
    
    final String langKey = "${selectedLanguage.value}_$name";
    
    // Check if we already have data or already requested it
    if (speciesData.containsKey(langKey) || _requestedSpecies.contains(langKey)) {
      return;
    }

    final lowerName = name.toLowerCase();
    final invalidNames = {'silence', 'unknown', 'speech', 'music', 'human voice', 'background noise', 'unidentified bird'};
    
    if (invalidNames.contains(lowerName) || lowerName.contains('unidentified')) {
      return; 
    }
    
    _fetchSpeciesInfo(name);
  }

  Future<void> _fetchSpeciesInfo(String name) async {
    final String langKey = "${selectedLanguage.value}_$name";
    _requestedSpecies.add(langKey);
    // Don't set global isLoadingWiki = true, as it blocks other UI. 
    // Just fetch silently and update map.
    
    try {
      final data = await _wikiService.getBirdInfo(name, languageCode: selectedLanguage.value);
      if (data != null) {
        speciesData[langKey] = data;
      }
    } catch (e) {
      print("Error fetching wiki for $name in ${selectedLanguage.value}: $e");
    }
  }

  void changeLanguage(String? code) {
    if (code == null || code == selectedLanguage.value) return;
    selectedLanguage.value = code;
    
    // Re-trigger info fetch for currently displayed species
    final predictions = recording.predictions?.entries.toList() ?? [];
    if (predictions.isEmpty && recording.commonName != null) {
        predictions.add(MapEntry(recording.commonName!, recording.confidence ?? 1.0));
    }
    
    for (var entry in predictions.take(5)) {
      resolveSpeciesInfo(entry.key);
    }
  }

  Future<void> _fetchRemoteDetections() async {
    try {
      final result = await _appwriteService.databases.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.detectionsCollectionId,
        queries: [Query.equal('recordings', recording.id)]
      );

      if (result.documents.isNotEmpty) {
        final detection = result.documents.first;
        final names = detection.data['scientificName'] as List?;
        final confs = detection.data['confidenceLevel'] as List?;

        if (names != null && names.isNotEmpty) {
          recording.commonName = names.first.toString();
          if (confs != null && confs.isNotEmpty) {
            recording.confidence = (confs.first as num).toDouble();
            
            final preds = <String, double>{};
            for (int i = 0; i < names.length; i++) {
              if (i < confs.length) {
                preds[names[i].toString()] = (confs[i] as num).toDouble();
              }
            }
            recording.predictions = preds;
          }
          // Update local storage too
          Get.find<StorageService>().updateRecording(recording);
        }
      }
    } catch (e) {
      print("Details: Error fetching remote detections: $e");
    }
  }

  // Removed _refreshSpeciesWiki and fetchSpeciesInfos (batch)
  
  Future<void> sendToResearch() async {
    if (localFilePath == null) {
      Get.snackbar('Error', 'Audio file not available locally.', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    researchProgress.value = 0.1;
    
    // Start background process
    _processResearchSubmission();

    // Show Progress Dialog
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.science, color: Colors.purple),
            SizedBox(width: 12),
            Text('Research Submission'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sending recording and metadata to the research group in the background.'),
            const SizedBox(height: 20),
            Obx(() => Column(
              children: [
                LinearProgressIndicator(
                  value: researchProgress.value,
                  backgroundColor: Colors.purple.withValues(alpha: 0.1),
                  color: Colors.purple,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(researchProgress.value * 100).toInt()}% Complete',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple),
                ),
              ],
            )),
          ],
        ),
        actions: [
          Obx(() => TextButton(
            onPressed: () {
              if (Get.isDialogOpen ?? false) Get.back();
            },
            child: Text(
              researchProgress.value >= 1.0 ? 'Done' : 'OK', 
              style: const TextStyle(
                fontWeight: FontWeight.bold, 
                color: Colors.purple
              )
            ),
          )),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      barrierDismissible: true,
    );
  }

  Future<void> _processResearchSubmission() async {
    final EvolutionApiService evoService = Get.find<EvolutionApiService>();

    try {
      // 1. Resolve Group JID
      researchProgress.value = 0.2;
      String? groupJid = await evoService.getGroupJidFromInvite(EvolutionApiService.groupInviteCode);
      groupJid ??= "120363044123456789@g.us"; 

      // 2. Prepare Metadata
      researchProgress.value = 0.4;
      final StringBuffer metadata = StringBuffer();
      metadata.writeln("🔬 *New Research Submission*");
      metadata.writeln("━━━━━━━━━━━━━━━━");
      metadata.writeln("*ID:* `${recording.id}`");
      metadata.writeln("*Date:* ${recording.timestamp.toIST().toString().split('.')[0]}");
      metadata.writeln("*Duration:* ${recording.duration.inSeconds}s");
      
      if (recording.latitude != null && recording.longitude != null) {
        metadata.writeln("*Location:* ${recording.latitude}, ${recording.longitude}");
        metadata.writeln("*Maps:* https://www.google.com/maps/search/?api=1&query=${recording.latitude},${recording.longitude}");
      }
      
      metadata.writeln("\n*Analysis Results:*");
      if (recording.commonName != null) {
        metadata.writeln("• Primary: *${recording.commonName}* (${(recording.confidence! * 100).toStringAsFixed(1)}%)");
      }
      
      if (recording.predictions != null && recording.predictions!.isNotEmpty) {
        final sorted = recording.predictions!.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        metadata.writeln("\n*Top Predictions:*");
        for (var entry in sorted.take(5)) {
          metadata.writeln("- ${entry.key}: ${(entry.value * 100).toStringAsFixed(1)}%");
        }
      }

      if (recording.notes != null && recording.notes!.isNotEmpty) {
        metadata.writeln("\n*Notes:* ${recording.notes}");
      }
      
      metadata.writeln("━━━━━━━━━━━━━━━━");
      metadata.writeln("_Sent via SoundScape Research Portal_");

      // 3. Send to WhatsApp
      researchProgress.value = 0.6;
      await evoService.sendMessage(groupJid, metadata.toString());
      
      researchProgress.value = 0.8;
      await evoService.sendAudio(groupJid, localFilePath!);
      
      researchProgress.value = 0.95;
      await evoService.sendDocument(groupJid, localFilePath!, p.basename(localFilePath!));

      // 4. Update local state
      recording.researchRequested = true;
      isSentToResearch.value = true;
      await Get.find<StorageService>().updateRecording(recording);
      
      // 5. Update remote state
      await _appwriteService.updateResearchStatus(recording.id, true);

      researchProgress.value = 1.0;
      
      // Close dialog automatically after a short delay
      await Future.delayed(const Duration(milliseconds: 1500));
      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar(
        'Success',
        'Data sent to research group successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print("Research Error: $e");
      // Don't reset to 0, keep it where it failed for context
      
      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar(
        'Research Submission Failed',
        'Could not send data: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
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

  Future<void> openInMaps() async {
    if (recording.latitude == null || recording.longitude == null) return;
    
    final lat = recording.latitude;
    final lng = recording.longitude;
    final url = Platform.isIOS 
        ? 'https://maps.apple.com/?q=$lat,$lng' 
        : 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
        
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
           volume: 0.0,
         );
         // Use waveform duration as initial truth for UI consistency
         if (waveformController.maxDuration > 0) {
            totalDuration.value = Duration(milliseconds: waveformController.maxDuration);
            remainingTime.value = totalDuration.value;
         }
      }
    } catch (e) {
      print("Waveform Error: $e");
    }
  }

  Future<void> _initPlayer() async {
    await player.openPlayer();
    player.setSubscriptionDuration(const Duration(milliseconds: 50)); // Faster updates for smoother visual
    player.onProgress?.listen((e) {
      currentPosition.value = e.position;
      
      // Update total duration if player gives a more accurate one, 
      // but keep UI consistent with waveform bounds
      if (e.duration.inMilliseconds > 0) {
        totalDuration.value = e.duration;
      }
      
      remainingTime.value = totalDuration.value - e.position;
      
      // Master Sync: Push audio position to waveform
      waveformController.seekTo(e.position.inMilliseconds);
      
      // Perform YAMNet analysis during playback
      _analyzeChunkAt(e.position);
    });

    // Handle manual seeking from waveform
    waveformController.onCurrentDurationChanged.listen((ms) {
      // Only seek player if the change is significant (manual seek) 
      // and not triggered by our own seekTo above
      final int diff = (ms - currentPosition.value.inMilliseconds).abs();
      if (diff > 300) { 
        player.seekToPlayer(Duration(milliseconds: ms));
      }
    });
  }

  Future<void> stopPlayer() async {
    await player.stopPlayer();
    // Reset waveform to start
    waveformController.seekTo(0);
    isPlaying.value = false;
    currentPosition.value = Duration.zero;
    remainingTime.value = totalDuration.value;
    _lastAnalysisTime = const Duration(seconds: -1); // Reset throttle
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
    timelineEvents.clear();
    
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
        
        // Populate Timeline Events
        if (_analysisService.topPredictions.isNotEmpty) {
           final top = _analysisService.topPredictions.first;
           if (top.value > 0.45 && top.key != 'Silence' && top.key != 'Unknown') {
             timelineEvents.add({
               'time': Duration(milliseconds: (i * inputSize / sampleRate * 1000).toInt()),
               'label': top.key,
               'confidence': top.value
             });
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
    
    try {
      waveformController.dispose();
    } catch (e) {
      print("Error disposing waveformController: $e");
    }
    
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
          await player.startPlayer(
            fromURI: localFilePath,
            whenFinished: () => stopPlayer(),
          );
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

  Future<void> reanalyzeRecording() async {
    if (isUploading.value) return;
    
    isUploading.value = true;
    try {
      await _appwriteService.reanalyzeRecording(recording);
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