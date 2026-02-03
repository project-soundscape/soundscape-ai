# 🐦 SoundScape - Bird Sound Recording & Identification

<div align="center">

![SoundScape Logo](assets/tflite/images/logo.jpeg)

**An intelligent mobile application for bird watching enthusiasts and citizen scientists**

[![Flutter Version](https://img.shields.io/badge/Flutter-3.9.0-02569B?logo=flutter)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.9.0-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Architecture](#-architecture) • [Contributing](#-contributing)

</div>

---

## 📋 Overview

**SoundScape** is a cross-platform mobile application that combines **audio recording**, **machine learning**, and **geolocation** to identify and catalog bird species. Built with Flutter and powered by TensorFlow Lite, SoundScape enables users to contribute to biodiversity monitoring through automated bird vocalization analysis.

### 🎯 Key Highlights

- 🎤 **High-Quality Recording**: Capture bird sounds with real-time waveform visualization
- 🤖 **AI-Powered Identification**: On-device ML using BirdNET model (500+ species)
- 📍 **GPS Tagging**: Automatic geolocation for every recording
- 📊 **Noise Monitoring**: Real-time decibel level measurement
- 🗺️ **Interactive Maps**: Visualize recordings on geographic maps
- 📱 **Offline-First**: Full functionality without internet connection
- ☁️ **Cloud Sync**: Seamless backup with Appwrite backend
- 🌐 **Cross-Platform**: iOS, Android, Linux, macOS, Windows, Web

---

## ✨ Features

### 🎵 Audio Recording
- Real-time audio capture with waveform visualization
- PCM WAV format (44.1kHz, 16-bit, mono)
- Audio level meter
- Minimum 15-second recording enforcement
- Speech detection to protect privacy

### 🧠 Machine Learning
- **YAMNet**: Speech detection model (521 audio classes)
- **BirdNET**: Bird species classification (500+ species)
- On-device inference (no internet required)
- Confidence scores for predictions
- Top 5 species predictions

### 📍 Geolocation & Mapping
- Automatic GPS tagging
- Interactive map with clustered markers
- Reverse geocoding (address from coordinates)
- Filter recordings by location and species
- Heatmap visualization

### 📱 User Interface
- Material Design 3
- Dark/Light theme support
- Intuitive tab navigation
- Real-time audio waveforms
- Compass and sensor integration

### ☁️ Cloud Integration
- Appwrite backend-as-a-service
- User authentication (email/password)
- Cloud storage for audio files
- Real-time sync across devices
- Offline queue management

### 📊 Analytics & Library
- Browse all recordings
- Search and filter capabilities
- Species information (Wikipedia integration)
- Export data (CSV, JSON)
- Community verification

---

## 🚀 Installation

### Prerequisites

- **Flutter SDK**: 3.9.0 or higher
- **Dart SDK**: 3.9.0 or higher
- **Android Studio** / **Xcode** (for mobile development)
- **Git**

### Clone the Repository

```bash
git clone https://github.com/muhammedshabeerop/SoundScape.git
cd SoundScape/frontend
```

### Install Dependencies

```bash
flutter pub get
```

### Configure Appwrite

1. Create an account at [Appwrite Cloud](https://cloud.appwrite.io)
2. Create a new project
3. Update `appwrite.config.json` with your credentials:

```json
{
  "projectId": "your-project-id",
  "endpoint": "https://fra.cloud.appwrite.io/v1",
  "databaseId": "your-database-id",
  "bucketId": "your-bucket-id"
}
```

### Run the Application

#### Android
```bash
flutter run -d android
```

#### iOS
```bash
flutter run -d ios
```

#### Desktop (Linux/macOS/Windows)
```bash
flutter run -d linux    # or macos, windows
```

#### Web
```bash
flutter run -d chrome
```

---

## 📱 Usage

### Recording Bird Sounds

1. **Launch App**: Open SoundScape and navigate to the Home tab
2. **Start Recording**: Tap the microphone button
3. **Grant Permissions**: Allow microphone and location access
4. **Record Audio**: Minimum 15 seconds (speech detection active)
5. **Stop Recording**: Tap the stop button
6. **View Results**: See species prediction with confidence scores

### Browsing Library

1. Navigate to **Library** tab
2. View all saved recordings
3. Use **search** to filter by species name
4. Tap a recording to view details
5. Play audio, see waveform, and species information

### Exploring the Map

1. Navigate to **Map** tab
2. View recordings as markers on map
3. Tap marker to see species and confidence
4. Use filters to show specific species or date ranges
5. Zoom and pan to explore different regions

### Monitoring Noise Levels

1. Open **Noise Monitor** from dashboard
2. Real-time decibel measurement displayed
3. View min/max/average values
4. Check noise level classification
5. Export noise data for analysis

---

## 🏗️ Architecture

### Tech Stack

| Component | Technology |
|-----------|------------|
| **Framework** | Flutter 3.9.0 |
| **Language** | Dart 3.9.0 |
| **State Management** | GetX 4.7.2 |
| **Backend** | Appwrite 20.3.3 |
| **Database (Local)** | Hive 2.2.3 |
| **Machine Learning** | TensorFlow Lite 0.12.1 |
| **Maps** | Flutter Map 8.2.2 |
| **Audio** | Flutter Sound 9.28.0 |

### Project Structure

```
lib/
├── app/
│   ├── modules/           # Feature modules
│   │   ├── auth/         # Authentication
│   │   ├── home/         # Recording module
│   │   ├── library/      # Browse recordings
│   │   ├── map/          # Geographic view
│   │   ├── details/      # Recording details
│   │   ├── settings/     # User preferences
│   │   └── dashboard/    # Main navigation
│   ├── routes/           # App routing
│   └── bindings/         # Dependency injection
├── services/             # Business logic
│   ├── appwrite_service.dart
│   ├── audio_analysis_service.dart
│   ├── location_service.dart
│   ├── storage_service.dart
│   └── sync_service.dart
├── models/               # Data models
└── main.dart            # Entry point

assets/
├── tflite/              # ML models
│   ├── yamnet.tflite
│   └── birdnet.tflite
└── images/              # App assets
```

### Data Flow

```
User Input → Controller → Service Layer → Data Layer
                ↓              ↓
         Local Storage   Cloud Sync (Appwrite)
```

---

## 🔧 Configuration

### Permissions

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSMicrophoneUsageDescription</key>
<string>SoundScape needs access to your microphone to record bird sounds</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>SoundScape needs your location to tag recordings</string>
```

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### Reporting Issues
- Use GitHub Issues to report bugs
- Include device info, OS version, and steps to reproduce
- Attach screenshots or logs if possible

### Development Workflow

1. **Fork** the repository
2. **Create** a feature branch
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit** your changes
   ```bash
   git commit -m "Add amazing feature"
   ```
4. **Push** to the branch
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open** a Pull Request

### Code Standards
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable/function names
- Add comments for complex logic
- Run `flutter analyze` before committing
- Format code with `flutter format .`

---

## 🧪 Testing

### Run Tests
```bash
flutter test
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

### Integration Tests
```bash
flutter drive --target=test_driver/app.dart
```

---

## 📦 Building for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ipa --release
```

### Desktop
```bash
flutter build linux --release
flutter build macos --release
flutter build windows --release
```

---

## 📚 Documentation

- **[Comprehensive Documentation](COMPREHENSIVE_DOCUMENTATION.md)** - Full technical documentation
- **[API Documentation](https://soundscape.app/docs)** - API reference
- **[User Guide](https://soundscape.app/guide)** - End-user documentation

---

## 🛠️ Troubleshooting

### Common Issues

**Issue**: App crashes on recording
- **Solution**: Ensure microphone permissions are granted in device settings

**Issue**: Species not identified
- **Solution**: Record for at least 15 seconds in a quiet environment

**Issue**: GPS coordinates showing as 0,0
- **Solution**: Enable location services and ensure GPS signal is available

**Issue**: Sync failing
- **Solution**: Check internet connection and Appwrite credentials

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 👥 Authors

- **Muhammed Shabeer OP** - *Initial work* - [GitHub](https://github.com/muhammedshabeerop)

---

## 🙏 Acknowledgments

- **BirdNET** team at Cornell Lab of Ornithology for the ML model
- **Google Research** for YAMNet model
- **Appwrite** for backend infrastructure
- **Flutter** team for the amazing framework
- **Xeno-canto** community for bird sound data

---

## 🌟 Star History

If you find this project useful, please consider giving it a ⭐!

---

## 📞 Contact & Support

- **Email**: support@soundscape.app
- **GitHub Issues**: [Report a bug](https://github.com/muhammedshabeerop/SoundScape/issues)
- **Discord**: [Join our community](https://discord.gg/soundscape)

---

<div align="center">

Made with ❤️ by the SoundScape Team

**[Website](https://soundscape.app)** • **[Documentation](COMPREHENSIVE_DOCUMENTATION.md)** • **[Report Bug](https://github.com/muhammedshabeerop/SoundScape/issues)**

</div>