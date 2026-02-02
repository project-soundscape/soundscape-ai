import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/recording_model.dart';

class StorageService extends GetxService {
  late Box<Map<dynamic, dynamic>> _box;
  late Box<dynamic> _settingsBox;
  final recordings = <Recording>[].obs;

  Future<StorageService> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('recordings');
    _settingsBox = await Hive.openBox('settings');
    _loadRecordings();
    return this;
  }

  // Settings
  bool get isDarkMode => _settingsBox.get('isDarkMode', defaultValue: false);
  set isDarkMode(bool val) => _settingsBox.put('isDarkMode', val);

  bool get notificationsEnabled => _settingsBox.get('notificationsEnabled', defaultValue: true);
  set notificationsEnabled(bool val) => _settingsBox.put('notificationsEnabled', val);

  bool get showRecordingInstructions => _settingsBox.get('showRecordingInstructions', defaultValue: true);
  set showRecordingInstructions(bool val) => _settingsBox.put('showRecordingInstructions', val);

  void _loadRecordings() {
    recordings.assignAll(
      _box.values.map((e) => Recording.fromMap(Map<String, dynamic>.from(e))).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
    );
  }

  List<Recording> getRecordings() {
    return recordings.toList();
  }

  Future<void> saveRecording(Recording recording) async {
    await _box.put(recording.id, recording.toMap());
    _loadRecordings();
  }

  Future<void> deleteRecording(String id) async {
    await _box.delete(id);
    _loadRecordings();
  }

  Future<void> updateRecording(Recording recording) async {
    await _box.put(recording.id, recording.toMap());
    // Optimization: Update the observable list directly instead of reloading everything
    final index = recordings.indexWhere((r) => r.id == recording.id);
    if (index != -1) {
      recordings[index] = recording;
      recordings.refresh(); // Trigger listeners
    } else {
      _loadRecordings();
    }
  }
}
