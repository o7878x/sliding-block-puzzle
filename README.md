# sliding_block_puzzle

A sliding-block puzzle game built with Flutter. Supports configurable grid
sizes, a difficulty score, a move counter and a timer, and persists the
selected grid size across sessions.

**Live demo:** <https://sliding-block-puzzle-o7878x.web.app>

## Requirements

- Flutter 3.44 or later (Dart SDK `^3.12.2`, see `pubspec.yaml`)
- A web browser for `flutter run -d chrome`, or a connected device/emulator

## Clone and run

```bash
git clone git@github.com:o7878x/sliding-block-puzzle.git
cd sliding-block-puzzle

flutter pub get
flutter run -d chrome
```

## Project structure

| Path | Purpose |
|---|---|
| `lib/main.dart` | Entry point, root `MaterialApp` and theme |
| `lib/models/puzzle_game.dart` | Core game logic — flat tile list, shuffle, moves, win detection, solvability via inversion-count parity |
| `lib/screens/game_screen.dart` | Game screen — responsive wide/narrow layouts, stats bar, timer |
| `lib/widgets/puzzle_board.dart` | Grid rendering with `Stack` + `AnimatedPositioned` for slide animation |
| `lib/widgets/puzzle_tile.dart` | Individual tile rendering |
| `lib/services/preferences_service.dart` | Caches preferences via `shared_preferences` (localStorage on web) |
| `lib/utils/puzzle_difficulty_calculator.dart` | Difficulty score from Manhattan distance + linear conflict |
| `lib/l10n/strings.dart` | UI strings |
| `test/` | Unit tests for game logic and a widget smoke test |
| `tools/generate_icon.dart` | Generates `assets/app_icon.png` |
| `web/` | Web runner and PWA manifest |

## Build and deploy

The app is deployed to Firebase Hosting from the `build/web` output directory
(see `firebase.json`). The app version comes from `version:` in `pubspec.yaml`,
so `flutter build` picks it up automatically.

```bash
# Install dependencies
flutter pub get

# Generate the web icons (required on a fresh clone, the outputs are gitignored)
dart run flutter_launcher_icons

# Build the release web bundle into build/web
flutter build web --release --wasm

# Deploy the built bundle to Firebase Hosting
firebase deploy --only hosting
```

The web icons (`web/favicon.png`, `web/icons/`) are generated from
`assets/app_icon.png` and are not tracked. `flutter build web` copies `web/`
verbatim into `build/web` without checking that they exist, so skipping the
generation step yields a deployed site with missing favicon and PWA icons.

`--wasm` compiles to WebAssembly with an automatic fallback to JavaScript, so
browsers without WasmGC support still get the CanvasKit build. Drop the flag to
ship the JavaScript build only.

Other useful variants:

```bash
# JavaScript build only
flutter build web --release

# Build with source maps for debugging a deployed build
flutter build web --profile --source-maps

# Serve the built bundle locally before deploying
firebase serve --only hosting
```

## Development

```bash
flutter analyze         # Static analysis
flutter test            # Run all tests
```

## Getting Started with Flutter

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
