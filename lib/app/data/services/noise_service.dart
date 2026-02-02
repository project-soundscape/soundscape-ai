import 'dart:math';
import 'package:get/get.dart';

class NoiseService extends GetxService {
  final RxDouble currentDb = 0.0.obs;
  final RxDouble maxDb = 0.0.obs;
  final RxDouble avgDb = 0.0.obs;
  
  List<double> _dbHistory = [];
  static const int _maxHistory = 100;

  void updateFromSamples(List<double> samples) {
    if (samples.isEmpty) return;
    
    // Calculate RMS (Root Mean Square)
    double sum = 0;
    for (var sample in samples) {
      sum += sample * sample;
    }
    double rms = sqrt(sum / samples.length);
    
    // Convert to Decibels
    // 20 * log10(RMS) -> relative to full scale (0 dBFS)
    // We add an offset to make it look like typical ambient noise (approx 30-100 dB)
    // A simple approximation: 20 * log10(rms) + 100 (tuning offset)
    double db = 0;
    if (rms > 0) {
      db = 20 * log(rms) / ln10 + 100;
    } else {
      db = 0;
    }
    
    // Clamp values
    if (db < 0) db = 0;
    if (db > 120) db = 120;

    currentDb.value = db;
    
    if (db > maxDb.value) {
      maxDb.value = db;
    }
    
    _dbHistory.add(db);
    if (_dbHistory.length > _maxHistory) {
      _dbHistory.removeAt(0);
    }
    
    avgDb.value = _dbHistory.reduce((a, b) => a + b) / _dbHistory.length;
  }

  void reset() {
    currentDb.value = 0.0;
    maxDb.value = 0.0;
    avgDb.value = 0.0;
    _dbHistory.clear();
  }
}
