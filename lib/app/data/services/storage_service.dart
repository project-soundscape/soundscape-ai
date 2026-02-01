import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/recording_model.dart';

class StorageService extends GetxService {
  late Box<Map<dynamic, dynamic>> _box;
  final recordings = <Recording>[].obs;

  Future<StorageService> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('recordings');
    _loadRecordings();
    return this;
  }

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
    _loadRecordings();
  }
}
