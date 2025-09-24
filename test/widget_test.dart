import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:soundscape_frontend/main.dart';
import 'package:soundscape_frontend/providers/soundscape_provider.dart';

void main() {
  testWidgets('App launches and displays home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SoundscapeApp());

    // Verify that the app title is displayed
    expect(find.text('Project Soundscape'), findsOneWidget);
    
    // Verify that the explore soundscapes text is displayed
    expect(find.text('Explore Soundscapes'), findsOneWidget);
    
    // Verify that the "Select a soundscape to start" message is displayed initially
    expect(find.text('Select a soundscape to start'), findsOneWidget);
  });

  testWidgets('Soundscape provider initializes with correct values', (WidgetTester tester) async {
    final provider = SoundscapeProvider();
    
    expect(provider.currentSoundscape, isNull);
    expect(provider.isPlaying, isFalse);
    expect(provider.volume, 0.7);
    expect(provider.soundscapes.length, 4);
    expect(provider.categories.length, 3);
  });

  testWidgets('Can select and play a soundscape', (WidgetTester tester) async {
    final provider = SoundscapeProvider();
    final soundscape = provider.soundscapes.first;
    
    provider.playSoundscape(soundscape);
    
    expect(provider.currentSoundscape, equals(soundscape));
    expect(provider.isPlaying, isTrue);
  });

  testWidgets('Can toggle play/pause', (WidgetTester tester) async {
    final provider = SoundscapeProvider();
    final soundscape = provider.soundscapes.first;
    
    provider.playSoundscape(soundscape);
    expect(provider.isPlaying, isTrue);
    
    provider.togglePlayPause();
    expect(provider.isPlaying, isFalse);
    
    provider.togglePlayPause();
    expect(provider.isPlaying, isTrue);
  });

  testWidgets('Can stop playback', (WidgetTester tester) async {
    final provider = SoundscapeProvider();
    final soundscape = provider.soundscapes.first;
    
    provider.playSoundscape(soundscape);
    expect(provider.currentSoundscape, equals(soundscape));
    expect(provider.isPlaying, isTrue);
    
    provider.stop();
    expect(provider.currentSoundscape, isNull);
    expect(provider.isPlaying, isFalse);
  });

  testWidgets('Can set volume', (WidgetTester tester) async {
    final provider = SoundscapeProvider();
    
    provider.setVolume(0.5);
    expect(provider.volume, 0.5);
    
    provider.setVolume(1.5); // Should be clamped to 1.0
    expect(provider.volume, 1.0);
    
    provider.setVolume(-0.5); // Should be clamped to 0.0
    expect(provider.volume, 0.0);
  });
}