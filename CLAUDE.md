# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this package is

`easy_audio_player` is a Flutter package (not an app). It provides three ready-made widgets (`MiniPlayer`, `ExpandedPlayer`, `PlayerControls`) backed by a singleton service that wraps `just_audio` and `just_audio_background`. The `example/` subdirectory is a standalone Flutter app that demonstrates the package.

## Commands

Run all tests (from repo root):
```
flutter test
```

Run a single test file:
```
flutter test test/widgets/mini_player_test.dart
```

Run a single named test:
```
flutter test --name "shows pause icon when PlayerPlaying"
```

Analyze / lint:
```
flutter analyze
```

Run the example app (from `example/`):
```
cd example && flutter run
```

Generate mocks (if mockito annotations are added):
```
dart run build_runner build --delete-conflicting-outputs
```

## Architecture

### Entry point and singleton lifecycle

`EasyAudioPlayer` (in `lib/src/core/easy_audio_player.dart`) is the sole public entry point. It owns the singleton `AudioPlayerService` and must be initialized once before `runApp()` via `EasyAudioPlayer.init(config: ...)`. It initializes both `JustAudioBackground` (for lock-screen notifications) and `AudioPlayerService`.

`AudioPlayerService` is intentionally **not exported** from `lib/easy_audio_player.dart`. The public API exposes it only as `AudioPlayerServiceInterface`, keeping the concrete implementation private and the public surface minimal.

### Service layer (`lib/src/core/`)

- `AudioPlayerServiceInterface` — abstract interface for all streams and controls. Widgets depend on this type, not the concrete class, to enable testing via `serviceOverride`.
- `AudioPlayerService` — concrete singleton. Bridges `just_audio`'s `AudioPlayer` to `BehaviorSubject`-backed streams. All streams replay their latest value immediately on subscription. `errorStream` is a `PublishSubject` (no replay). On any playback error it auto-skips to the next track and emits on `errorStream`.
- `TrackSourceMapper` — converts `AudioTrack` instances into `just_audio` `AudioSource` objects with `MediaItem` tags (for background notifications). Not exported publicly.
- `audio_player_config.dart` — `AudioPlayerConfig` holds the Android notification channel config passed to `JustAudioBackground.init`.
- `audio_player_state.dart` — `EasyPlayerState` sealed class with subtypes: `PlayerIdle`, `PlayerBuffering`, `PlayerPlaying(position)`, `PlayerPaused(position)`, `PlayerCompleted`, `PlayerError(error)`. Always use exhaustive `switch` on this type.

### Models (`lib/src/models/`)

- `AudioTrack` — two named constructors: `.network(url:…)` and `.file(file:…)`. Equality is by `id`. Internal fields (`_sourceType`, `_url`, `_file`) are exposed via getters for use by `TrackSourceMapper` and `WaveformWidget` within `src/` but are not part of the public API surface.
- `AudioPlayerTheme` — all fields nullable. Call `AudioPlayerTheme.of(context, override: theme)` inside `build()` to resolve against the ambient Material 3 `ColorScheme`/`TextTheme`. Never call `.resolve()` directly; use the static `of` factory.
- `EasyLoopMode` — `off | one | all`. Maps 1-to-1 to `just_audio`'s `LoopMode`.
- `AudioPlayerError` — carries `trackId`, `message`, `category` (`AudioErrorCategory` enum), and the original error object.

### Widgets (`lib/src/widgets/`)

All three public widgets (`MiniPlayer`, `ExpandedPlayer`, `PlayerControls`) and all component widgets accept a `serviceOverride` parameter for injection in tests. In production they call `EasyAudioPlayer.service`.

All widgets use `StreamBuilder` to react to service streams. They never hold playback state locally.

`ExpandedPlayer` with `showPlaylist: true` wraps the playlist in `Expanded` — it must have a bounded-height parent (e.g. `Scaffold` body). With `showPlaylist: false` it can be used in unbounded contexts.

`WaveformWidget` (and the exported `isWaveformSupported` boolean): waveform extraction only works on **Android, iOS, macOS** and only for **local file tracks** (`AudioTrack.file`). Network tracks silently show a progress bar. The `showWaveform` flag on `ExpandedPlayer` is ignored on web/Linux/Windows.

### Known technical debt

`AudioPlayerService.load()` uses `ConcatenatingAudioSource` which is deprecated in `just_audio` 0.10.0 but still functional. A migration to the new playlist API is pending confirmation of `just_audio_background` compatibility (see TODO comment in `audio_player_service.dart`).

## Testing patterns

Widget tests use `MockAudioPlayerService` from `test/helpers/mock_audio_player_service.dart`. It mirrors all `BehaviorSubject` streams and exposes `emit*` helpers to drive state:

```dart
mockService.emitState(const PlayerPlaying(Duration.zero));
mockService.emitCurrentTrack(AudioTrack.network(id: '1', url: '…', title: 'Song'));
mockService.emitError(AudioPlayerError(…));
```

Always `dispose()` the mock in `tearDown`. Widget tests never call `EasyAudioPlayer.init()` — they pass `serviceOverride` to avoid platform channel dependencies.

Unit tests for models and state are in `test/models/` and `test/core/`. They do not need mocks.

## Platform constraints

| Feature | Android | iOS | macOS | Web | Linux | Windows |
|---|---|---|---|---|---|---|
| Background playback | ✓ | ✓ | — | — | — | — |
| Lock-screen controls | ✓ | ✓ | — | — | — | — |
| Waveform visualization | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |

Android requires `minSdkVersion 21`. See README for the full `AndroidManifest.xml` and `Info.plist` setup required for background playback.
