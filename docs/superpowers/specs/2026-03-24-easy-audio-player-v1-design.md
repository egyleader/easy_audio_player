# easy_audio_player v1.0 — Design Specification

**Date:** 2026-03-24
**Status:** Approved

---

## Overview

A complete rewrite of `easy_audio_player` targeting Dart 3 / Flutter 3.27+. The package provides drop-in audio player widgets with background playback, notification controls, and Material 3 adaptive theming. Built on `just_audio 0.10.x` + `just_audio_background 0.0.1-beta.17`.

**Core value proposition:** The only Flutter package combining polished UI widgets + background playback + notification controls + zero-config setup.

---

## 1. Package Structure

```
lib/
├── easy_audio_player.dart              # single public export
└── src/
    ├── core/
    │   ├── easy_audio_player.dart      # static init() + dispose()
    │   ├── audio_player_service.dart   # singleton, streams, controls
    │   ├── audio_player_state.dart     # sealed class EasyPlayerState
    │   └── audio_player_config.dart    # AudioPlayerConfig model
    ├── models/
    │   ├── audio_track.dart            # AudioTrack with named constructors
    │   └── audio_player_theme.dart     # M3-adaptive AudioPlayerTheme
    └── widgets/
        ├── mini_player.dart
        ├── expanded_player.dart
        └── player_controls.dart

example/
└── lib/
    ├── main.dart
    └── screens/
        ├── mini_player_screen.dart
        ├── expanded_player_screen.dart
        ├── player_controls_screen.dart
        └── features_screen.dart
```

Everything under `src/` is private. Only exports from `easy_audio_player.dart` are public API.

---

## 2. Dependencies

```yaml
environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.27.0'

dependencies:
  just_audio: ^0.10.5
  just_audio_background: ^0.0.1-beta.17
  audio_session: ^0.2.3
  just_waveform: ^0.0.7
  rxdart: ^0.28.0
  audio_video_progress_bar: ^2.0.0
```

---

## 3. Lifecycle

### Initialization (required in `main()` before `runApp()`)

```dart
void main() async {
  await EasyAudioPlayer.init(
    config: AudioPlayerConfig(
      androidNotificationChannelId: 'com.myapp.audio',   // required
      androidNotificationChannelName: 'Music Player',     // required
      androidNotificationIcon: 'mipmap/ic_launcher',      // optional
      notificationColor: Color(0xFF000000),               // optional
    ),
  );
  runApp(MyApp());
}
```

`just_audio_background` requires init before `runApp()` on Android — lazy init is not viable.

### Disposal

```dart
await EasyAudioPlayer.dispose();
```

Cancels all stream subscriptions, closes all BehaviorSubjects, disposes the AudioPlayer instance, stops the background service. The singleton resets so `init()` can be called again if needed.

### Service Access

```dart
final service = EasyAudioPlayer.service;
```

Single singleton accessed anywhere in the app after `init()`.

---

## 4. AudioTrack Model

Named constructors follow Flutter's `Image.network` / `Image.file` / `Image.asset` pattern.

```dart
// Network stream
AudioTrack.network({
  required String id,
  required String url,
  required String title,
  String? artist,
  String? album,
  String? artworkUrl,
  Duration? duration,
  Map<String, dynamic>? extras,
})

// Local device file
AudioTrack.file({
  required String id,
  required File file,
  required String title,
  String? artist,
  String? album,
  String? artworkUrl,
  Duration? duration,
  Map<String, dynamic>? extras,
})

// Bundled asset
AudioTrack.asset({
  required String id,
  required String assetPath,
  required String title,
  String? artist,
  String? album,
  String? artworkUrl,
  Duration? duration,
  Map<String, dynamic>? extras,
})
```

Translated internally to `just_audio` source types. `MediaItem` never leaks into public API.

---

## 5. AudioPlayerService

### Architecture

Service subscribes to `just_audio` streams once at `init()` time. Subscriptions are stored and live for the entire service lifetime — not per-widget. Each stream is backed by a `BehaviorSubject<T>` which always holds the last value. Widgets can subscribe/unsubscribe freely without affecting state correctness.

Platform events (notification pause, lock screen controls, audio focus loss, headphone disconnect) route back through `just_audio`'s own streams via `just_audio_background`, so the BehaviorSubject pipeline catches them automatically.

### Internal Playlist Implementation Note

`just_audio 0.10.x` deprecated `ConcatenatingAudioSource` in favour of a new playlist API. `just_audio_background 0.0.1-beta.17` depends on `just_audio_platform_interface ^4.5.0` (same interface version as `just_audio 0.10.5`), confirming compatibility. During implementation, verify whether the new playlist API is `AudioPlayer.setAudioSources()` or direct mutation methods, and use whichever is current. If `ConcatenatingAudioSource` is still present and functional in 0.10.5 (deprecated ≠ removed), use it as a fallback only — prefer the new API to avoid a future breaking upgrade.

### Sealed State Class

```dart
sealed class EasyPlayerState {}
class PlayerIdle      extends EasyPlayerState {}
class PlayerBuffering extends EasyPlayerState {}
class PlayerPlaying   extends EasyPlayerState { final Duration position; }
class PlayerPaused    extends EasyPlayerState { final Duration position; }
class PlayerCompleted extends EasyPlayerState {}
class PlayerError     extends EasyPlayerState { final AudioPlayerError error; }
```

### AudioPlayerError Type

```dart
enum AudioErrorCategory { network, decode, notFound, permission, unknown }

class AudioPlayerError {
  final String trackId;       // id of the track that failed
  final String message;       // human-readable description
  final AudioErrorCategory category;
  final Object? originalError; // underlying just_audio error, for debugging
}
```

### EasyLoopMode Enum

The package defines its own `EasyLoopMode` to avoid leaking `just_audio`'s `LoopMode` into the public API. Translated internally.

```dart
enum EasyLoopMode { off, one, all }
```

### Streams + Sync Getters

Every stream has a matching synchronous getter for reading current value without subscribing:

```dart
Stream<EasyPlayerState>   playerStateStream   / playerState
Stream<Duration>          positionStream       / position
Stream<Duration?>         durationStream       / duration
Stream<Duration>          bufferedStream       / buffered
Stream<AudioTrack?>       currentTrackStream   / currentTrack
Stream<List<AudioTrack>>  queueStream          / queue
Stream<EasyLoopMode>      loopModeStream       / loopMode
Stream<bool>              shuffleStream        / shuffleEnabled
Stream<double>            volumeStream         / volume
Stream<double>            speedStream          / speed
Stream<AudioPlayerError>  errorStream          // no sync getter — errors are events
```

### Playlist Management

```dart
service.load(List<AudioTrack> tracks, {int initialIndex = 0})
service.add(AudioTrack track)
service.insert(int index, AudioTrack track)
service.remove(int index)
service.move(int from, int to)
service.clear()
service.skipToIndex(int index)
```

`load()` defaults to starting from track 0. Pass `initialIndex` to start from a specific position atomically — this avoids the two-call race condition of `load()` + `skipToIndex()`.

### Playback Controls

```dart
service.play()
service.pause()
service.stop()
service.seek(Duration position)
service.skipToNext()
service.skipToPrevious()
service.setVolume(double volume)     // 0.0–1.0
service.setSpeed(double speed)       // 0.5–2.0
service.setLoopMode(EasyLoopMode mode)
service.setShuffle(bool enabled)
```

### Error Handling

On track load failure: skip to next track automatically AND emit on `errorStream`. Developer can subscribe to `errorStream` for logging or custom handling without blocking playback.

```dart
service.errorStream.listen((error) {
  print('Track failed: ${error.trackId} — ${error.message}');
});
```

---

## 6. Widgets

### MiniPlayer

Persistent bottom-bar style. Shows: artwork thumbnail + title + artist + progress indicator + play/pause button.

```dart
MiniPlayer(
  theme: AudioPlayerTheme(...), // optional
  onTap: () {},                 // optional — e.g. show ExpandedPlayer
)
```

### ExpandedPlayer

Full view. Shows: large artwork + title + artist + album + seekbar + control buttons + optional waveform + optional playlist.

```dart
ExpandedPlayer(
  showWaveform: false,  // default false
  // NOTE: showWaveform uses just_waveform which only supports Android, iOS,
  // and macOS. On web, Linux, and Windows this parameter is silently ignored.
  showPlaylist: true,   // default true
  theme: AudioPlayerTheme(...),
)
```

### PlayerControls

Headless — only renders control buttons with no layout opinions. For developers building custom UI around the service.

```dart
PlayerControls(
  showVolume: true,
  showSpeed: true,
  showShuffle: true,
  showLoop: true,
  theme: AudioPlayerTheme(...),
)
```

---

## 7. AudioPlayerTheme

All fields optional. Inherits from `Theme.of(context)` by default — reads `ColorScheme` and `TextTheme` automatically. Pass only what you want to override.

```dart
AudioPlayerTheme({
  Color? primaryColor,         // default: ColorScheme.primary
  Color? backgroundColor,      // default: ColorScheme.surface
  TextStyle? titleStyle,        // default: TextTheme.titleMedium
  TextStyle? subtitleStyle,     // default: TextTheme.bodyMedium
  Color? progressBarColor,      // default: ColorScheme.primary
  Color? bufferedBarColor,      // default: ColorScheme.surfaceContainerHighest
  Color? waveformColor,         // default: ColorScheme.primary @ 0.6 opacity
  IconThemeData? iconTheme,     // default: app IconTheme
  double? borderRadius,         // default: 12.0
  double? miniArtworkSize,      // default: 48
  double? expandedArtworkSize,  // default: 240
})
```

---

## 8. Platform Requirements

### Android
- `minSdkVersion: 19`
- `targetSdkVersion: 35`
- AGP `8.5.2`
- Manifest permissions: `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `POST_NOTIFICATIONS`
- Service declaration: `android:foregroundServiceType="mediaPlayback"`
- Activity: extend `AudioServiceActivity`
- **Runtime permission (API 33+):** `POST_NOTIFICATIONS` must be requested at runtime on Android 13+. The consuming app is responsible for calling `ActivityCompat.requestPermissions` (or using `permission_handler` package). Without it, the media notification is silently suppressed on API 33+ devices. The package README must document this clearly with a code example.

### Waveform Platform Limitations
`just_waveform` supports Android, iOS, and macOS only. The `showWaveform` parameter on `ExpandedPlayer` is silently ignored on web, Linux, and Windows. This is documented in code at the parameter declaration site and in the README platform requirements section.

### iOS
- iOS 12.0+
- `UIBackgroundModes: [audio]` in Info.plist

---

## 9. Example App

Four-tab bottom navigation app. All tabs share the same `EasyAudioPlayer.service` singleton.

| Tab | Demonstrates |
|---|---|
| **Mini** | `MiniPlayer` with track list; tapping a track loads and plays it |
| **Expanded** | `ExpandedPlayer` with waveform toggle + full playlist reorder/dismiss |
| **Controls** | `PlayerControls` in a custom-built layout (headless usage demo) |
| **Features** | Error handling (bad URL shows a SnackBar via `errorStream`), local asset playback, loop/shuffle, speed control |

---

## 10. Migration Notes (from old API)

| Old | New |
|---|---|
| `initJustAudioBackground(NotificationSettings(...))` | `EasyAudioPlayer.init(config: AudioPlayerConfig(...))` |
| `ConcatenatingAudioSource` | `service.load(List<AudioTrack>)` |
| `AudioSource.uri(..., tag: MediaItem(...))` | `AudioTrack.network(...)` |
| `AudioPlayerService()` | `EasyAudioPlayer.service` |
| `BasicAudioPlayer` / `MinimalAudioPlayer` | `MiniPlayer` / `PlayerControls` |
| `FullAudioPlayer` | `ExpandedPlayer` |
| `textTheme.headline6` | `textTheme.titleLarge` |
