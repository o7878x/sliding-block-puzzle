# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Get dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run all tests
flutter test

# Run a single test
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage

# Run on connected device/emulator
flutter run

# Run for web
flutter run -d chrome

# Build for distribution
flutter build apk              # Android APK
flutter build appbundle        # Android App Bundle
flutter build ios              # iOS (requires macOS + Xcode)
flutter build web              # Web
flutter build windows          # Windows
flutter build linux            # Linux
flutter build macos            # macOS

# Check outdated dependencies
flutter pub outdated

# Upgrade dependencies (major versions)
flutter pub upgrade --major-versions
```

## Code Architecture

### Project intent

Sliding-block puzzle game built with Flutter, targeting Android, iOS, Web, Windows, macOS, and Linux. Currently at the initial `flutter create` scaffold — the app is still the default counter demo with no custom logic.

### Source layout

| Path | Purpose |
|---|---|
| `lib/main.dart` | Single entry point — `main()`, root `MaterialApp`, and home screen widget |
| `test/widget_test.dart` | Single smoke test verifying the counter widget renders and responds to taps |
| `android/` | Android platform runner (Kotlin/Gradle) |
| `ios/` | iOS platform runner (Swift/Obj-C) |
| `web/` | Web platform runner (HTML/CSS) |
| `windows/` | Windows platform runner (C++/CMake) |
| `linux/` | Linux platform runner (C++/CMake) |
| `macos/` | macOS platform runner (Swift) |
| `analysis_options.yaml` | Lint rules — uses `package:flutter_lints/flutter.yaml` defaults |

### Current patterns

- **State management**: Local `setState` in `StatefulWidget` (no BLoC/Riverpod/Provider yet)
- **Widget tree**: `MaterialApp` → `Scaffold` → `AppBar` + `Column` + `FloatingActionButton`
- **Dependencies**: `flutter` SDK, `cupertino_icons`, `flutter_test` (dev), `flutter_lints` (dev)
- **SDK constraint**: Dart `^3.12.2`

### When adding code

- Place new Dart source files in `lib/`, organized by feature or layer (e.g. `lib/models/`, `lib/screens/`, `lib/widgets/`, `lib/game_logic/`)
- Mirror test files in `test/` with the same relative path
- For platform-specific code, use Flutter's `dart:io` or platform channels rather than touching the runner directories
