import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart'; // for Colors
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/recording_model.dart';
import '../../../data/services/appwrite_service.dart';
import '../../../data/services/wiki_service.dart';

class DetailsController extends GetxController {
  late Recording recording;
  final player = FlutterSoundPlayer();
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  final WikiService _wikiService = Get.put(WikiService());
  
  // Waveform Controller
  late PlayerController waveformController;
  
  RxBool isPlaying = false.obs;
  Rx<Duration> currentPosition = Duration.zero.obs;
  Rx<Duration> totalDuration = Duration.zero.obs;
  RxBool isUploading = false.obs;
  
  String? localFilePath;
  
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
      _initPlayer();
      _prepareWaveform();
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
    try {
      if (isPlaying.value) {
        if (player.isPlaying) {
          await player.pausePlayer();
        }
        isPlaying.value = false;
        // isPaused.value = true; // This line was not in the original file content
      } else {
        if (player.isPaused) {
          if (player.isPaused) {
            await player.resumePlayer();
          } else {
             // Fallback if state is desynced
             await player.startPlayer(fromURI: localFilePath, codec: Codec.aacMP4);
          }
        } else {
          await player.startPlayer(fromURI: localFilePath, codec: Codec.aacMP4);
        }
        isPlaying.value = true;
        // isPaused.value = false; // This line was not in the original file content
      }
    } catch (e) {
      Get.snackbar("Error", "Playback error: $e");
      // Reset state on error
      isPlaying.value = false;
      // isPaused.value = false; // This line was not in the original file content
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