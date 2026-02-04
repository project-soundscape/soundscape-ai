# SoundScape - Copilot Instructions

## Build & Run Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run -d android      # Android
flutter run -d ios          # iOS
flutter run -d chrome       # Web
flutter run -d linux        # Desktop

# Analyze code (linting)
flutter analyze

# Format code
dart format .

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart
```

## Architecture Overview

This is a **Flutter** bird sound recording and identification app using **GetX** for state management and dependency injection.

### Layer Structure

```
User Input → Controller → Service Layer → Data Layer (Hive/Appwrite)
```

### Key Components

- **Services** (`lib/app/data/services/`) - Singleton business logic registered in `main.dart` via `Get.put()` / `Get.putAsync()`
- **Controllers** - Per-module state management extending `GetxController`
- **Bindings** - Dependency injection per route via `GetPage` bindings
- **Models** (`lib/app/data/models/`) - Data classes for recordings

### Service Initialization (main.dart)

Services are initialized in order with async dependencies awaited:
1. `StorageService` (Hive local DB)
2. `AppwriteService` (cloud backend)
3. `WikiService`, `NotificationService`
4. `ModelDownloadService`, `LocationService`, `NoiseService`
5. `SyncService`

### Module Structure

Each feature module in `lib/app/modules/` follows:
```
module_name/
├── bindings/       # DI setup
├── controllers/    # GetxController with Rx observables
└── views/          # Widget UI
```

### ML Pipeline

- **YAMNet** (`yamnet.tflite`) - Speech detection (521 classes, 16kHz)
- **BirdNET** (external models) - Bird classification (48kHz, 3s window)
- `AudioAnalysisService` handles model loading and real-time inference
- Audio buffer of `currentInputSize` samples triggers analysis

## Key Conventions

### GetX Patterns

- Use `RxBool`, `RxString`, `RxList<T>` for reactive state in controllers
- Access services via `Get.find<ServiceName>()`
- Register services: `Get.put()` (eager) or `Get.lazyPut()` (lazy) in bindings
- Navigate with `Get.toNamed(Routes.ROUTE_NAME)`

### Audio Recording

- Minimum 15 seconds required for valid recordings
- Speech detection (>70% confidence) discards recordings automatically
- WAV format: 16-bit PCM, mono channel, sample rate from active ML model
- File saved to app documents directory

### Routing

Routes defined in `lib/app/routes/app_pages.dart` with corresponding `_Paths` constants.

### Backend Integration

- Appwrite credentials in `appwrite.config.json`
- Offline-first: local Hive storage with background cloud sync
- `SyncService` manages upload queue

### Asset Loading

ML models and labels in `assets/tflite/`:
- Models loaded via `Interpreter.fromAsset()` for bundled assets
- External models loaded from documents directory
