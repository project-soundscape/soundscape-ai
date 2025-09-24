import 'package:flutter/material.dart';
import '../models/soundscape.dart';

class SoundscapeProvider extends ChangeNotifier {
  Soundscape? _currentSoundscape;
  bool _isPlaying = false;
  double _volume = 0.7;
  
  // Mock soundscape data
  final List<Soundscape> _soundscapes = [
    Soundscape(
      id: '1',
      name: 'Forest Rain',
      description: 'Gentle rain falling in a peaceful forest',
      category: 'Nature',
      audioUrl: 'assets/sounds/forest_rain.mp3',
      imageUrl: 'assets/images/forest.jpg',
      duration: const Duration(minutes: 10),
    ),
    Soundscape(
      id: '2',
      name: 'Ocean Waves',
      description: 'Rhythmic waves crashing on the shore',
      category: 'Water',
      audioUrl: 'assets/sounds/ocean_waves.mp3',
      imageUrl: 'assets/images/ocean.jpg',
      duration: const Duration(minutes: 15),
    ),
    Soundscape(
      id: '3',
      name: 'City Night',
      description: 'Ambient city sounds at night',
      category: 'Urban',
      audioUrl: 'assets/sounds/city_night.mp3',
      imageUrl: 'assets/images/city.jpg',
      duration: const Duration(minutes: 8),
    ),
    Soundscape(
      id: '4',
      name: 'Campfire',
      description: 'Crackling fire with distant nature sounds',
      category: 'Nature',
      audioUrl: 'assets/sounds/campfire.mp3',
      imageUrl: 'assets/images/campfire.jpg',
      duration: const Duration(minutes: 12),
    ),
  ];

  // Getters
  Soundscape? get currentSoundscape => _currentSoundscape;
  bool get isPlaying => _isPlaying;
  double get volume => _volume;
  List<Soundscape> get soundscapes => _soundscapes;
  
  List<String> get categories {
    return _soundscapes.map((s) => s.category).toSet().toList();
  }

  List<Soundscape> getSoundscapesByCategory(String category) {
    return _soundscapes.where((s) => s.category == category).toList();
  }

  // Methods
  void playSoundscape(Soundscape soundscape) {
    _currentSoundscape = soundscape;
    _isPlaying = true;
    notifyListeners();
    
    // TODO: Implement actual audio playback
    debugPrint('Playing: ${soundscape.name}');
  }

  void togglePlayPause() {
    if (_currentSoundscape != null) {
      _isPlaying = !_isPlaying;
      notifyListeners();
      
      // TODO: Implement actual play/pause logic
      debugPrint(_isPlaying ? 'Resumed' : 'Paused');
    }
  }

  void stop() {
    _isPlaying = false;
    _currentSoundscape = null;
    notifyListeners();
    
    // TODO: Implement actual stop logic
    debugPrint('Stopped');
  }

  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0);
    notifyListeners();
    
    // TODO: Implement actual volume control
    debugPrint('Volume set to: $_volume');
  }
}