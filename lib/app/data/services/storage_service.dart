import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/recording_model.dart';

class StorageService extends GetxService {
  late Box<Map<dynamic, dynamic>> _box;

  Future<StorageService> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('recordings');
    return this;
  }

  List<Recording> getRecordings() {
    return _box.values.map((e) => Recording.fromMap(Map<String, dynamic>.from(e))).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> saveRecording(Recording recording) async {
    await _box.put(recording.id, recording.toMap());
  }

  Future<void> deleteRecording(String id) async {
    await _box.delete(id);
  }

  Future<void> updateRecording(Recording recording) async {
    await _box.put(recording.id, recording.toMap());
  }
}
