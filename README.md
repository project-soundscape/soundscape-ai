# Project Soundscape - Frontend

A Flutter application that provides a frontend interface for Project Soundscape, allowing users to explore and play various ambient soundscapes for relaxation and focus.

## Features

- 🎵 **Soundscape Library**: Browse different categories of ambient sounds
- 🎛️ **Audio Controls**: Play, pause, and volume control for soundscapes
- 📱 **Cross-Platform**: Runs on Android, iOS, and Web
- 🎨 **Material Design**: Modern, responsive UI following Material Design 3
- 🔊 **Categories**: Organized soundscapes by Nature, Water, Urban, and more

## Available Soundscapes

The app currently includes sample soundscapes in different categories:

### Nature
- **Forest Rain**: Gentle rain falling in a peaceful forest
- **Campfire**: Crackling fire with distant nature sounds

### Water
- **Ocean Waves**: Rhythmic waves crashing on the shore

### Urban
- **City Night**: Ambient city sounds at night

## Getting Started

### Prerequisites

- Flutter SDK 3.16.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code (for development)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/project-soundscape/frontend.git
   cd frontend
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Building for Different Platforms

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

#### Web
```bash
flutter build web --release
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   └── soundscape.dart         # Soundscape data model
├── providers/
│   └── soundscape_provider.dart # State management
├── screens/
│   └── home_screen.dart        # Main app screen
├── widgets/
│   ├── soundscape_player.dart  # Audio player widget
│   └── sound_category_grid.dart # Category grid widget
└── services/                   # Future: API services
```

## State Management

The app uses the Provider pattern for state management:

- **SoundscapeProvider**: Manages the current playing soundscape, playback state, volume, and available soundscapes

## Testing

Run the test suite:
```bash
flutter test
```

The tests cover:
- Widget rendering and UI components
- Provider state management
- Audio playback controls
- Volume management

## Development

### Adding New Soundscapes

To add new soundscapes, update the `_soundscapes` list in `lib/providers/soundscape_provider.dart`:

```dart
Soundscape(
  id: 'unique_id',
  name: 'Soundscape Name',
  description: 'Description of the soundscape',
  category: 'Category Name',
  audioUrl: 'assets/sounds/audio_file.mp3',
  imageUrl: 'assets/images/image_file.jpg',
  duration: Duration(minutes: 10),
)
```

### Adding New Categories

New categories are automatically detected from the soundscapes. Simply use a new category name in your soundscape definition.

## Future Enhancements

- [ ] Audio playback implementation (currently using placeholder)
- [ ] Backend API integration
- [ ] User favorites and playlists
- [ ] Custom soundscape mixing
- [ ] Offline audio caching
- [ ] Sleep timer functionality
- [ ] Background audio playback

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is part of Project Soundscape and follows the project's licensing terms.