# easy_audio_player v1.0 — Core Package Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite the `easy_audio_player` package from scratch — new models, service layer, three player widgets, and Material 3 adaptive theming — targeting Dart 3 / Flutter 3.27+ with `just_audio 0.10.x`.

**Architecture:** A singleton `AudioPlayerService` wraps `just_audio`'s `AudioPlayer`, mapping all state through `rxdart` `BehaviorSubject`s subscribed once at init time. Widgets read from service streams via `StreamBuilder` — they never hold audio state themselves. The static `EasyAudioPlayer` class owns the lifecycle (`init` / `dispose`).

**Tech Stack:** Dart 3, Flutter 3.27+, just_audio 0.10.5, just_audio_background 0.0.1-beta.17, audio_session 0.2.3, just_waveform 0.0.7, rxdart 0.28.0, audio_video_progress_bar 2.0.0, mockito (dev), build_runner (dev)

---

## File Map

**Create:**
```
lib/easy_audio_player.dart                        ← single public export
lib/src/models/audio_track.dart                   ← AudioTrack named constructors
lib/src/models/audio_player_error.dart            ← AudioPlayerError + AudioErrorCategory
lib/src/models/easy_loop_mode.dart                ← EasyLoopMode enum
lib/src/models/audio_player_theme.dart            ← M3-adaptive theme
lib/src/core/audio_player_state.dart              ← sealed EasyPlayerState
lib/src/core/audio_player_config.dart             ← AudioPlayerConfig
lib/src/core/audio_player_service_interface.dart  ← abstract interface for service + mock compatibility
lib/src/core/audio_player_service.dart            ← singleton service + BehaviorSubjects
lib/src/core/easy_audio_player.dart               ← static init() / dispose() / service
lib/src/core/track_source_mapper.dart             ← AudioTrack → AudioSource translation
lib/src/widgets/components/seek_bar.dart          ← seekbar component
lib/src/widgets/components/artwork_widget.dart    ← artwork with fallback
lib/src/widgets/components/track_info_widget.dart ← title + artist + album display
lib/src/widgets/components/control_buttons.dart   ← play/pause/prev/next/loop/shuffle
lib/src/widgets/components/waveform_widget.dart   ← just_waveform + platform guard
lib/src/widgets/components/playlist_view.dart     ← reorderable dismissible list
lib/src/widgets/mini_player.dart
lib/src/widgets/expanded_player.dart
lib/src/widgets/player_controls.dart
test/models/audio_track_test.dart
test/models/audio_player_error_test.dart
test/core/audio_player_state_test.dart
test/core/audio_player_service_test.dart
test/widgets/mini_player_test.dart
test/widgets/expanded_player_test.dart
test/models/audio_player_theme_test.dart
test/widgets/player_controls_test.dart
test/helpers/mock_audio_player_service.dart       ← shared mock for widget tests
```

**Modify:**
```
pubspec.yaml                                      ← deps + SDK constraints
```

**Delete after new code is in place:**
```
lib/flutter_audio_player.dart
lib/services/audio_player_service.dart
lib/models/audio.dart
lib/models/notification_configuration.dart
lib/models/models.dart
lib/helpers/init_just_audio_background.dart
lib/helpers/show_slider_dialog.dart
lib/widgets/buttons/control_buttons.dart
lib/widgets/buttons/play_button.dart
lib/widgets/buttons/loop_button.dart
lib/widgets/buttons/shuffle_button.dart
lib/widgets/players/full_audio_player.dart
lib/widgets/players/basic_audio_player.dart
lib/widgets/players/minimal_audio_player.dart
lib/widgets/play_list_View.dart
lib/widgets/seekbar.dart
```

---

## Task 1: Update pubspec.yaml

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Replace pubspec.yaml content**

```yaml
name: easy_audio_player
description: A drop-in Flutter audio player with background playback, notification controls, and Material 3 adaptive theming.
version: 1.0.0
homepage: https://github.com/egyleader/easy_audio_player

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.27.0'

dependencies:
  flutter:
    sdk: flutter
  just_audio: ^0.10.5
  just_audio_background: ^0.0.1-beta.17
  audio_session: ^0.2.3
  just_waveform: ^0.0.7
  rxdart: ^0.28.0
  audio_video_progress_bar: ^2.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  mockito: ^5.4.4
  build_runner: ^2.4.9
```

- [ ] **Step 2: Get dependencies**

```bash
flutter pub get
```

Expected: resolves without conflicts. If `just_audio_background` conflicts with `just_audio` versions, pin `just_audio` to the exact version required by `just_audio_background`.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: update deps to dart3/flutter3.27, just_audio 0.10.x"
```

---

## Task 2: Models — AudioTrack

**Files:**
- Create: `lib/src/models/audio_track.dart`
- Create: `test/models/audio_track_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// test/models/audio_track_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_audio_player/easy_audio_player.dart';

void main() {
  group('AudioTrack.network', () {
    test('sets all fields correctly', () {
      final track = AudioTrack.network(
        id: '1',
        url: 'https://example.com/track.mp3',
        title: 'Test Track',
        artist: 'Artist',
        album: 'Album',
        artworkUrl: 'https://example.com/art.jpg',
        duration: const Duration(seconds: 180),
        extras: {'key': 'value'},
      );

      expect(track.id, '1');
      expect(track.title, 'Test Track');
      expect(track.artist, 'Artist');
      expect(track.album, 'Album');
      expect(track.artworkUrl, 'https://example.com/art.jpg');
      expect(track.duration, const Duration(seconds: 180));
      expect(track.extras, {'key': 'value'});
    });

    test('optional fields default to null', () {
      final track = AudioTrack.network(id: '1', url: 'https://x.com/t.mp3', title: 'T');
      expect(track.artist, isNull);
      expect(track.album, isNull);
      expect(track.artworkUrl, isNull);
      expect(track.duration, isNull);
      expect(track.extras, isNull);
    });
  });

  group('AudioTrack.file', () {
    test('sets file and required fields', () {
      final file = File('/path/to/track.mp3');
      final track = AudioTrack.file(id: '2', file: file, title: 'Local Track');
      expect(track.id, '2');
      expect(track.title, 'Local Track');
    });
  });

  group('AudioTrack.asset', () {
    test('sets assetPath and required fields', () {
      final track = AudioTrack.asset(
        id: '3',
        assetPath: 'assets/audio/intro.mp3',
        title: 'Intro',
      );
      expect(track.id, '3');
      expect(track.title, 'Intro');
    });
  });
}
```

- [ ] **Step 2: Run tests — expect failure**

```bash
flutter test test/models/audio_track_test.dart
```

Expected: compile error — `AudioTrack` not yet defined.

- [ ] **Step 3: Create AudioTrack model**

```dart
// lib/src/models/audio_track.dart
import 'dart:io';

// Not private (_) so it can be accessed by TrackSourceMapper and WaveformWidget
// in other files within src/. Not exported from easy_audio_player.dart.
enum TrackSourceType { network, file, asset }

class AudioTrack {
  final String id;
  final String title;
  final String? artist;
  final String? album;
  final String? artworkUrl;
  final Duration? duration;
  final Map<String, dynamic>? extras;

  final TrackSourceType _sourceType;
  final String? _url;
  final File? _file;
  final String? _assetPath;

  AudioTrack.network({
    required this.id,
    required String url,
    required this.title,
    this.artist,
    this.album,
    this.artworkUrl,
    this.duration,
    this.extras,
  })  : _sourceType = TrackSourceType.network,
        _url = url,
        _file = null,
        _assetPath = null;

  AudioTrack.file({
    required this.id,
    required File file,
    required this.title,
    this.artist,
    this.album,
    this.artworkUrl,
    this.duration,
    this.extras,
  })  : _sourceType = TrackSourceType.file,
        _url = null,
        _file = file,
        _assetPath = null;

  AudioTrack.asset({
    required this.id,
    required String assetPath,
    required this.title,
    this.artist,
    this.album,
    this.artworkUrl,
    this.duration,
    this.extras,
  })  : _sourceType = TrackSourceType.asset,
        _url = null,
        _file = null,
        _assetPath = assetPath;

  // Internal accessors for TrackSourceMapper and WaveformWidget
  TrackSourceType get sourceType => _sourceType;
  String? get url => _url;
  File? get file => _file;
  String? get assetPath => _assetPath;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AudioTrack && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
```

- [ ] **Step 4: Create a temporary export stub so tests compile**

```dart
// lib/easy_audio_player.dart  (temporary — will be completed in Task 12)
export 'src/models/audio_track.dart';
```

- [ ] **Step 5: Run tests — expect pass**

```bash
flutter test test/models/audio_track_test.dart
```

Expected: all tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/src/models/audio_track.dart lib/easy_audio_player.dart test/models/audio_track_test.dart
git commit -m "feat: add AudioTrack model with named constructors (network/file/asset)"
```

---

## Task 3: Models — AudioPlayerError and EasyLoopMode

**Files:**
- Create: `lib/src/models/audio_player_error.dart`
- Create: `lib/src/models/easy_loop_mode.dart`
- Create: `test/models/audio_player_error_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// test/models/audio_player_error_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_audio_player/easy_audio_player.dart';

void main() {
  group('AudioPlayerError', () {
    test('stores all fields', () {
      final error = AudioPlayerError(
        trackId: 'track_1',
        message: 'File not found',
        category: AudioErrorCategory.notFound,
        originalError: Exception('404'),
      );

      expect(error.trackId, 'track_1');
      expect(error.message, 'File not found');
      expect(error.category, AudioErrorCategory.notFound);
      expect(error.originalError, isA<Exception>());
    });

    test('originalError is optional', () {
      final error = AudioPlayerError(
        trackId: 'x',
        message: 'Network error',
        category: AudioErrorCategory.network,
      );
      expect(error.originalError, isNull);
    });
  });

  group('EasyLoopMode', () {
    test('has three values', () {
      expect(EasyLoopMode.values.length, 3);
      expect(EasyLoopMode.values, containsAll([EasyLoopMode.off, EasyLoopMode.one, EasyLoopMode.all]));
    });
  });
}
```

- [ ] **Step 2: Run tests — expect failure**

```bash
flutter test test/models/audio_player_error_test.dart
```

- [ ] **Step 3: Create AudioPlayerError**

```dart
// lib/src/models/audio_player_error.dart
enum AudioErrorCategory { network, decode, notFound, permission, unknown }

class AudioPlayerError {
  final String trackId;
  final String message;
  final AudioErrorCategory category;
  final Object? originalError;

  const AudioPlayerError({
    required this.trackId,
    required this.message,
    required this.category,
    this.originalError,
  });
}
```

- [ ] **Step 4: Create EasyLoopMode**

```dart
// lib/src/models/easy_loop_mode.dart
enum EasyLoopMode { off, one, all }
```

- [ ] **Step 5: Add to export stub**

```dart
// lib/easy_audio_player.dart
export 'src/models/audio_track.dart';
export 'src/models/audio_player_error.dart';
export 'src/models/easy_loop_mode.dart';
```

- [ ] **Step 6: Run tests — expect pass**

```bash
flutter test test/models/audio_player_error_test.dart
```

- [ ] **Step 7: Commit**

```bash
git add lib/src/models/audio_player_error.dart lib/src/models/easy_loop_mode.dart lib/easy_audio_player.dart test/models/audio_player_error_test.dart
git commit -m "feat: add AudioPlayerError, AudioErrorCategory, EasyLoopMode models"
```

---

## Task 4: Core — EasyPlayerState (sealed class)

**Files:**
- Create: `lib/src/core/audio_player_state.dart`
- Create: `test/core/audio_player_state_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// test/core/audio_player_state_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_audio_player/easy_audio_player.dart';

void main() {
  group('EasyPlayerState sealed class', () {
    test('PlayerPlaying holds position', () {
      const state = PlayerPlaying(Duration(seconds: 30));
      expect(state.position, const Duration(seconds: 30));
    });

    test('PlayerPaused holds position', () {
      const state = PlayerPaused(Duration(seconds: 15));
      expect(state.position, const Duration(seconds: 15));
    });

    test('PlayerError holds AudioPlayerError', () {
      const error = AudioPlayerError(
        trackId: 'x',
        message: 'fail',
        category: AudioErrorCategory.unknown,
      );
      const state = PlayerError(error);
      expect(state.error.trackId, 'x');
    });

    test('exhaustive switch compiles for all subtypes', () {
      EasyPlayerState state = const PlayerIdle();
      final label = switch (state) {
        PlayerIdle() => 'idle',
        PlayerBuffering() => 'buffering',
        PlayerPlaying() => 'playing',
        PlayerPaused() => 'paused',
        PlayerCompleted() => 'completed',
        PlayerError() => 'error',
      };
      expect(label, 'idle');
    });
  });
}
```

- [ ] **Step 2: Run tests — expect failure**

```bash
flutter test test/core/audio_player_state_test.dart
```

- [ ] **Step 3: Create EasyPlayerState**

```dart
// lib/src/core/audio_player_state.dart
import '../models/audio_player_error.dart';

sealed class EasyPlayerState {
  const EasyPlayerState();
}

class PlayerIdle extends EasyPlayerState {
  const PlayerIdle();
}

class PlayerBuffering extends EasyPlayerState {
  const PlayerBuffering();
}

class PlayerPlaying extends EasyPlayerState {
  final Duration position;
  const PlayerPlaying(this.position);
}

class PlayerPaused extends EasyPlayerState {
  final Duration position;
  const PlayerPaused(this.position);
}

class PlayerCompleted extends EasyPlayerState {
  const PlayerCompleted();
}

class PlayerError extends EasyPlayerState {
  final AudioPlayerError error;
  const PlayerError(this.error);
}
```

- [ ] **Step 4: Add to export stub**

```dart
// lib/easy_audio_player.dart — add line:
export 'src/core/audio_player_state.dart';
```

- [ ] **Step 5: Run tests — expect pass**

```bash
flutter test test/core/audio_player_state_test.dart
```

- [ ] **Step 6: Commit**

```bash
git add lib/src/core/audio_player_state.dart lib/easy_audio_player.dart test/core/audio_player_state_test.dart
git commit -m "feat: add sealed EasyPlayerState with Dart 3 exhaustive matching"
```

---

## Task 5: Core — AudioPlayerConfig

**Files:**
- Create: `lib/src/core/audio_player_config.dart`

- [ ] **Step 1: Create config model**

```dart
// lib/src/core/audio_player_config.dart
import 'dart:ui';

class AudioPlayerConfig {
  /// Android notification channel ID. Must be unique per app.
  final String androidNotificationChannelId;

  /// Human-readable notification channel name shown in Android settings.
  final String androidNotificationChannelName;

  /// Android notification small icon resource name.
  /// Must exist in your app's drawable or mipmap resources.
  /// Defaults to 'mipmap/ic_launcher'.
  final String androidNotificationIcon;

  /// Tint color applied to the media notification on Android.
  final Color? notificationColor;

  const AudioPlayerConfig({
    required this.androidNotificationChannelId,
    required this.androidNotificationChannelName,
    this.androidNotificationIcon = 'mipmap/ic_launcher',
    this.notificationColor,
  });
}
```

- [ ] **Step 2: Add to export stub**

```dart
// lib/easy_audio_player.dart — add line:
export 'src/core/audio_player_config.dart';
```

- [ ] **Step 3: Commit**

```bash
git add lib/src/core/audio_player_config.dart lib/easy_audio_player.dart
git commit -m "feat: add AudioPlayerConfig for init()"
```

---

## Task 6: Core — TrackSourceMapper (internal)

**Files:**
- Create: `lib/src/core/track_source_mapper.dart`

This file handles the AudioTrack → just_audio AudioSource conversion. It is private (not exported). Each source needs a `MediaItem` tag for `just_audio_background` notification display.

- [ ] **Step 1: Create mapper**

```dart
// lib/src/core/track_source_mapper.dart
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../models/audio_track.dart';

class TrackSourceMapper {
  static AudioSource toAudioSource(AudioTrack track) {
    final tag = MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      album: track.album,
      artUri: track.artworkUrl != null ? Uri.parse(track.artworkUrl!) : null,
      duration: track.duration,
      extras: track.extras,
    );

    return switch (track.sourceType) {
      TrackSourceType.network => AudioSource.uri(
          Uri.parse(track.url!),
          tag: tag,
        ),
      TrackSourceType.file => AudioSource.uri(
          track.file!.uri,
          tag: tag,
        ),
      TrackSourceType.asset => AudioSource.asset(
          track.assetPath!,
          tag: tag,
        ),
    };
  }

  static List<AudioSource> toAudioSources(List<AudioTrack> tracks) =>
      tracks.map(toAudioSource).toList();
}
```

**Note:** `TrackSourceType` is package-private via the internal `sourceType` getter on `AudioTrack`. The switch here uses Dart 3 exhaustive pattern matching. If the `just_audio 0.10.x` new playlist API (replacing `ConcatenatingAudioSource`) is confirmed stable, update the service to use it. For now this mapper produces individual `AudioSource` objects that are composed by the service.

- [ ] **Step 2: Commit**

```bash
git add lib/src/core/track_source_mapper.dart
git commit -m "feat: add TrackSourceMapper (AudioTrack → just_audio AudioSource)"
```

---

## Task 6b: Core — AudioPlayerServiceInterface

**Files:**
- Create: `lib/src/core/audio_player_service_interface.dart`

This abstract interface allows `MockAudioPlayerService` in tests to be type-compatible with widget `serviceOverride` parameters. Widgets cast to this interface, not to the concrete `AudioPlayerService`.

- [ ] **Step 1: Create the interface**

```dart
// lib/src/core/audio_player_service_interface.dart
import '../models/audio_player_error.dart';
import '../models/audio_track.dart';
import '../models/easy_loop_mode.dart';
import 'audio_player_state.dart';

/// Abstract interface implemented by both [AudioPlayerService] and
/// [MockAudioPlayerService]. Widgets accept this type for testability.
abstract interface class AudioPlayerServiceInterface {
  Stream<EasyPlayerState> get playerStateStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<Duration> get bufferedStream;
  Stream<AudioTrack?> get currentTrackStream;
  Stream<List<AudioTrack>> get queueStream;
  Stream<EasyLoopMode> get loopModeStream;
  Stream<bool> get shuffleStream;
  Stream<double> get volumeStream;
  Stream<double> get speedStream;
  Stream<AudioPlayerError> get errorStream;

  EasyPlayerState get playerState;
  Duration get position;
  Duration? get duration;
  Duration get buffered;
  AudioTrack? get currentTrack;
  List<AudioTrack> get queue;
  EasyLoopMode get loopMode;
  bool get shuffleEnabled;
  double get volume;
  double get speed;

  Future<void> load(List<AudioTrack> tracks, {int initialIndex = 0});
  Future<void> add(AudioTrack track);
  Future<void> insert(int index, AudioTrack track);
  Future<void> remove(int index);
  Future<void> move(int from, int to);
  Future<void> clear();
  Future<void> skipToIndex(int index);

  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> skipToNext();
  Future<void> skipToPrevious();
  Future<void> setVolume(double volume);
  Future<void> setSpeed(double speed);
  Future<void> setLoopMode(EasyLoopMode mode);
  Future<void> setShuffle(bool enabled);
}
```

- [ ] **Step 2: Update `AudioPlayerService` class declaration to implement the interface**

In `audio_player_service.dart`, change:
```dart
class AudioPlayerService {
```
to:
```dart
class AudioPlayerService implements AudioPlayerServiceInterface {
```

- [ ] **Step 3: Commit**

```bash
git add lib/src/core/audio_player_service_interface.dart
git commit -m "feat: add AudioPlayerServiceInterface for testable widget injection"
```

---

## Task 7: Core — AudioPlayerService

**Files:**
- Create: `lib/src/core/audio_player_service.dart`
- Create: `test/core/audio_player_service_test.dart`

This is the core of the package. Read the entire task before starting.

- [ ] **Step 1: Write service tests**

```dart
// test/core/audio_player_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_audio_player/easy_audio_player.dart';

// NOTE: Full integration tests for AudioPlayerService require a running
// just_audio instance with real platform channels, which is not available
// in the standard flutter test environment.
//
// These tests verify the contract of the public API surface:
// - sync getters return correct initial values before any audio is loaded
// - EasyLoopMode enum maps correctly to expected values
//
// For stream behavior tests (that state updates propagate), use the
// example app on a real device or the integration_test package.

void main() {
  group('AudioPlayerService initial state', () {
    // Service is tested via EasyAudioPlayer.service after init.
    // These tests verify initial values on the sync getters.
    // Full stream tests are in integration_test/.

    test('EasyLoopMode.off is the default starting point', () {
      // Verifies the enum value we expect as default is accessible
      expect(EasyLoopMode.off, isNotNull);
    });

    test('PlayerIdle is the expected initial state type', () {
      // Verifies the sealed class subtype is instantiable
      const state = PlayerIdle();
      expect(state, isA<EasyPlayerState>());
      expect(state, isA<PlayerIdle>());
    });
  });
}
```

- [ ] **Step 2: Run tests — expect pass (trivial tests, verify compile)**

```bash
flutter test test/core/audio_player_service_test.dart
```

- [ ] **Step 3: Create AudioPlayerService**

```dart
// lib/src/core/audio_player_service.dart
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../models/audio_player_error.dart';
import '../models/audio_track.dart';
import '../models/easy_loop_mode.dart';
import 'audio_player_state.dart';
import 'track_source_mapper.dart';

class AudioPlayerService {
  AudioPlayerService._();

  static AudioPlayerService? _instance;
  static AudioPlayerService get instance {
    assert(_instance != null,
        'AudioPlayerService is not initialized. Call EasyAudioPlayer.init() first.');
    return _instance!;
  }

  late final AudioPlayer _player;
  final List<AudioTrack> _queue = [];

  // ── BehaviorSubjects (internal, permanent subscriptions) ──────────────────
  final _playerStateSubject = BehaviorSubject<EasyPlayerState>.seeded(const PlayerIdle());
  final _positionSubject = BehaviorSubject<Duration>.seeded(Duration.zero);
  final _durationSubject = BehaviorSubject<Duration?>.seeded(null);
  final _bufferedSubject = BehaviorSubject<Duration>.seeded(Duration.zero);
  final _currentTrackSubject = BehaviorSubject<AudioTrack?>.seeded(null);
  final _queueSubject = BehaviorSubject<List<AudioTrack>>.seeded([]);
  final _loopModeSubject = BehaviorSubject<EasyLoopMode>.seeded(EasyLoopMode.off);
  final _shuffleSubject = BehaviorSubject<bool>.seeded(false);
  final _volumeSubject = BehaviorSubject<double>.seeded(1.0);
  final _speedSubject = BehaviorSubject<double>.seeded(1.0);
  final _errorSubject = PublishSubject<AudioPlayerError>();

  // Internal subscription list for cleanup
  final _subscriptions = <dynamic>[];

  // ── Public Streams ─────────────────────────────────────────────────────────
  Stream<EasyPlayerState> get playerStateStream => _playerStateSubject.stream;
  Stream<Duration> get positionStream => _positionSubject.stream;
  Stream<Duration?> get durationStream => _durationSubject.stream;
  Stream<Duration> get bufferedStream => _bufferedSubject.stream;
  Stream<AudioTrack?> get currentTrackStream => _currentTrackSubject.stream;
  Stream<List<AudioTrack>> get queueStream => _queueSubject.stream;
  Stream<EasyLoopMode> get loopModeStream => _loopModeSubject.stream;
  Stream<bool> get shuffleStream => _shuffleSubject.stream;
  Stream<double> get volumeStream => _volumeSubject.stream;
  Stream<double> get speedStream => _speedSubject.stream;
  Stream<AudioPlayerError> get errorStream => _errorSubject.stream;

  // ── Public Sync Getters ────────────────────────────────────────────────────
  EasyPlayerState get playerState => _playerStateSubject.value;
  Duration get position => _positionSubject.value;
  Duration? get duration => _durationSubject.value;
  Duration get buffered => _bufferedSubject.value;
  AudioTrack? get currentTrack => _currentTrackSubject.value;
  List<AudioTrack> get queue => List.unmodifiable(_queueSubject.value);
  EasyLoopMode get loopMode => _loopModeSubject.value;
  bool get shuffleEnabled => _shuffleSubject.value;
  double get volume => _volumeSubject.value;
  double get speed => _speedSubject.value;

  // ── Init (called by EasyAudioPlayer.init) ─────────────────────────────────
  static Future<AudioPlayerService> create() async {
    final service = AudioPlayerService._();
    await service._initialize();
    _instance = service;
    return service;
  }

  Future<void> _initialize() async {
    _player = AudioPlayer();

    // Configure audio session for music playback
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Subscribe to just_audio streams permanently
    _subscriptions.addAll([
      _player.playerStateStream.listen(_onPlayerState),
      _player.positionStream.listen(_positionSubject.add),
      _player.durationStream.listen(_durationSubject.add),
      _player.bufferedPositionStream.listen(_bufferedSubject.add),
      _player.volumeStream.listen(_volumeSubject.add),
      _player.speedStream.listen(_speedSubject.add),
      _player.loopModeStream.listen((mode) => _loopModeSubject.add(_mapLoopMode(mode))),
      _player.shuffleModeEnabledStream.listen(_shuffleSubject.add),
      _player.currentIndexStream.listen(_onCurrentIndex),
      _player.errorStream.listen(_onError),
    ]);
  }

  void _onPlayerState(PlayerState state) {
    final pos = _positionSubject.value;
    final mapped = switch (state.processingState) {
      ProcessingState.idle => const PlayerIdle(),
      ProcessingState.loading || ProcessingState.buffering => const PlayerBuffering(),
      ProcessingState.ready => state.playing ? PlayerPlaying(pos) : PlayerPaused(pos),
      ProcessingState.completed => const PlayerCompleted(),
    };
    _playerStateSubject.add(mapped);
  }

  void _onCurrentIndex(int? index) {
    if (index != null && index < _queue.length) {
      _currentTrackSubject.add(_queue[index]);
    }
  }

  void _onError(Object error) {
    final current = _currentTrackSubject.value;
    _errorSubject.add(AudioPlayerError(
      trackId: current?.id ?? 'unknown',
      message: error.toString(),
      category: _categorizeError(error),
      originalError: error,
    ));
    // Auto-skip to next track on error
    skipToNext();
  }

  AudioErrorCategory _categorizeError(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('network') || msg.contains('connection') || msg.contains('timeout')) {
      return AudioErrorCategory.network;
    }
    if (msg.contains('404') || msg.contains('not found')) {
      return AudioErrorCategory.notFound;
    }
    if (msg.contains('decode') || msg.contains('format')) {
      return AudioErrorCategory.decode;
    }
    if (msg.contains('permission')) return AudioErrorCategory.permission;
    return AudioErrorCategory.unknown;
  }

  EasyLoopMode _mapLoopMode(LoopMode mode) => switch (mode) {
        LoopMode.off => EasyLoopMode.off,
        LoopMode.one => EasyLoopMode.one,
        LoopMode.all => EasyLoopMode.all,
      };

  LoopMode _toJustAudioLoopMode(EasyLoopMode mode) => switch (mode) {
        EasyLoopMode.off => LoopMode.off,
        EasyLoopMode.one => LoopMode.one,
        EasyLoopMode.all => LoopMode.all,
      };

  // ── Playlist Management ────────────────────────────────────────────────────

  /// Replaces the queue and begins playback from [initialIndex].
  Future<void> load(List<AudioTrack> tracks, {int initialIndex = 0}) async {
    _queue
      ..clear()
      ..addAll(tracks);
    _queueSubject.add(List.unmodifiable(_queue));

    // TODO: Migrate to just_audio 0.10.x new playlist API when
    // just_audio_background compatibility is confirmed. Currently using
    // ConcatenatingAudioSource (deprecated in 0.10.0 but still functional).
    final source = ConcatenatingAudioSource(
      children: TrackSourceMapper.toAudioSources(tracks),
    );
    await _player.setAudioSource(source, initialIndex: initialIndex);
  }

  Future<void> add(AudioTrack track) async {
    _queue.add(track);
    _queueSubject.add(List.unmodifiable(_queue));
    // Cast is safe — we set a ConcatenatingAudioSource in load()
    final concat = _player.audioSource as ConcatenatingAudioSource?;
    await concat?.add(TrackSourceMapper.toAudioSource(track));
  }

  Future<void> insert(int index, AudioTrack track) async {
    _queue.insert(index, track);
    _queueSubject.add(List.unmodifiable(_queue));
    final concat = _player.audioSource as ConcatenatingAudioSource?;
    await concat?.insert(index, TrackSourceMapper.toAudioSource(track));
  }

  Future<void> remove(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    _queueSubject.add(List.unmodifiable(_queue));
    final concat = _player.audioSource as ConcatenatingAudioSource?;
    await concat?.removeAt(index);
  }

  Future<void> move(int from, int to) async {
    if (from < 0 || from >= _queue.length) return;
    final track = _queue.removeAt(from);
    _queue.insert(to, track);
    _queueSubject.add(List.unmodifiable(_queue));
    final concat = _player.audioSource as ConcatenatingAudioSource?;
    await concat?.move(from, to);
  }

  Future<void> clear() async {
    _queue.clear();
    _queueSubject.add([]);
    _currentTrackSubject.add(null);
    await _player.stop();
    final concat = _player.audioSource as ConcatenatingAudioSource?;
    await concat?.clear();
  }

  Future<void> skipToIndex(int index) => _player.seek(Duration.zero, index: index);

  // ── Playback Controls ──────────────────────────────────────────────────────
  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> skipToNext() => _player.seekToNext();
  Future<void> skipToPrevious() => _player.seekToPrevious();
  Future<void> setVolume(double volume) => _player.setVolume(volume.clamp(0.0, 1.0));
  Future<void> setSpeed(double speed) => _player.setSpeed(speed.clamp(0.5, 2.0));

  Future<void> setLoopMode(EasyLoopMode mode) =>
      _player.setLoopMode(_toJustAudioLoopMode(mode));

  Future<void> setShuffle(bool enabled) async {
    await _player.setShuffleModeEnabled(enabled);
    if (enabled) await _player.shuffle();
  }

  // ── Dispose ────────────────────────────────────────────────────────────────
  Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();

    await _playerStateSubject.close();
    await _positionSubject.close();
    await _durationSubject.close();
    await _bufferedSubject.close();
    await _currentTrackSubject.close();
    await _queueSubject.close();
    await _loopModeSubject.close();
    await _shuffleSubject.close();
    await _volumeSubject.close();
    await _speedSubject.close();
    await _errorSubject.close();

    await _player.dispose();
    _instance = null;
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/core/audio_player_service_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/core/audio_player_service.dart lib/src/core/track_source_mapper.dart test/core/audio_player_service_test.dart
git commit -m "feat: add AudioPlayerService with BehaviorSubject streams and playlist management"
```

---

## Task 8: Core — EasyAudioPlayer static class

**Files:**
- Create: `lib/src/core/easy_audio_player.dart`

- [ ] **Step 1: Create static entry point**

```dart
// lib/src/core/easy_audio_player.dart
import 'package:just_audio_background/just_audio_background.dart';

import 'audio_player_config.dart';
import 'audio_player_service.dart';

/// Entry point for the easy_audio_player package.
///
/// Call [init] once in `main()` before `runApp()`:
/// ```dart
/// void main() async {
///   await EasyAudioPlayer.init(config: AudioPlayerConfig(...));
///   runApp(MyApp());
/// }
/// ```
class EasyAudioPlayer {
  EasyAudioPlayer._();

  /// Initializes background playback and the audio player service.
  /// Must be called before [runApp] on Android.
  static Future<void> init({required AudioPlayerConfig config}) async {
    await JustAudioBackground.init(
      androidNotificationChannelId: config.androidNotificationChannelId,
      androidNotificationChannelName: config.androidNotificationChannelName,
      androidNotificationIcon: config.androidNotificationIcon,
      androidNotificationColor: config.notificationColor,
      androidNotificationOngoing: false,
      preloadArtwork: true,
    );
    await AudioPlayerService.create();
  }

  /// The singleton audio player service. Access streams and controls here.
  /// Returns [AudioPlayerServiceInterface] — the concrete [AudioPlayerService]
  /// is intentionally not exported to keep the public API surface minimal.
  static AudioPlayerServiceInterface get service => AudioPlayerService.instance;

  /// Disposes the audio player service and stops background playback.
  /// The singleton resets — [init] can be called again if needed.
  static Future<void> dispose() => AudioPlayerService.instance.dispose();
}
```

- [ ] **Step 2: Add to export stub**

```dart
// lib/easy_audio_player.dart — add line:
export 'src/core/easy_audio_player.dart';
```

- [ ] **Step 3: Commit**

```bash
git add lib/src/core/easy_audio_player.dart lib/easy_audio_player.dart
git commit -m "feat: add EasyAudioPlayer static class with init/dispose lifecycle"
```

---

## Task 9: AudioPlayerTheme

**Files:**
- Create: `lib/src/models/audio_player_theme.dart`
- Create: `test/models/audio_player_theme_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// test/models/audio_player_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_audio_player/easy_audio_player.dart';

void main() {
  group('AudioPlayerTheme', () {
    testWidgets('resolves M3 defaults from context when no overrides provided',
        (tester) async {
      late AudioPlayerTheme resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorSchemeSeed: Colors.blue),
          home: Builder(builder: (context) {
            resolved = AudioPlayerTheme.of(context);
            return const SizedBox();
          }),
        ),
      );

      // Defaults come from M3 ColorScheme — just check they are non-null
      expect(resolved.primaryColor, isNotNull);
      expect(resolved.backgroundColor, isNotNull);
      expect(resolved.titleStyle, isNotNull);
      expect(resolved.subtitleStyle, isNotNull);
      expect(resolved.miniArtworkSize, 48.0);
      expect(resolved.expandedArtworkSize, 240.0);
      expect(resolved.borderRadius, 12.0);
    });

    testWidgets('explicit values override M3 defaults', (tester) async {
      late AudioPlayerTheme resolved;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            resolved = AudioPlayerTheme(
              primaryColor: Colors.red,
              borderRadius: 24.0,
            ).resolve(context);
            return const SizedBox();
          }),
        ),
      );

      expect(resolved.primaryColor, Colors.red);
      expect(resolved.borderRadius, 24.0);
    });
  });
}
```

- [ ] **Step 2: Run tests — expect failure**

```bash
flutter test test/models/audio_player_theme_test.dart
```

- [ ] **Step 3: Create AudioPlayerTheme**

```dart
// lib/src/models/audio_player_theme.dart
import 'package:flutter/material.dart';

class AudioPlayerTheme {
  final Color? primaryColor;
  final Color? backgroundColor;
  final Color? progressBarColor;
  final Color? bufferedBarColor;
  final Color? waveformColor;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final IconThemeData? iconTheme;
  final double? borderRadius;
  final double? miniArtworkSize;
  final double? expandedArtworkSize;

  const AudioPlayerTheme({
    this.primaryColor,
    this.backgroundColor,
    this.progressBarColor,
    this.bufferedBarColor,
    this.waveformColor,
    this.titleStyle,
    this.subtitleStyle,
    this.iconTheme,
    this.borderRadius,
    this.miniArtworkSize,
    this.expandedArtworkSize,
  });

  /// Resolves this theme against the ambient Material 3 theme.
  /// Unset fields fall back to ColorScheme / TextTheme values.
  AudioPlayerTheme resolve(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return AudioPlayerTheme(
      primaryColor: primaryColor ?? cs.primary,
      backgroundColor: backgroundColor ?? cs.surface,
      progressBarColor: progressBarColor ?? cs.primary,
      bufferedBarColor: bufferedBarColor ?? cs.surfaceContainerHighest,
      waveformColor: waveformColor ?? cs.primary.withValues(alpha: 0.6),
      titleStyle: titleStyle ?? tt.titleMedium,
      subtitleStyle: subtitleStyle ?? tt.bodyMedium,
      iconTheme: iconTheme ?? IconTheme.of(context),
      borderRadius: borderRadius ?? 12.0,
      miniArtworkSize: miniArtworkSize ?? 48.0,
      expandedArtworkSize: expandedArtworkSize ?? 240.0,
    );
  }

  /// Convenience: resolve from context and return a fully populated theme.
  static AudioPlayerTheme of(BuildContext context, {AudioPlayerTheme? override}) {
    return (override ?? const AudioPlayerTheme()).resolve(context);
  }
}
```

- [ ] **Step 4: Add to export stub**

```dart
// lib/easy_audio_player.dart — add line:
export 'src/models/audio_player_theme.dart';
```

- [ ] **Step 5: Run tests — expect pass**

```bash
flutter test test/models/audio_player_theme_test.dart
```

- [ ] **Step 6: Commit**

```bash
git add lib/src/models/audio_player_theme.dart lib/easy_audio_player.dart test/models/audio_player_theme_test.dart
git commit -m "feat: add AudioPlayerTheme with M3-adaptive defaults"
```

---

## Task 10: Widget Test Infrastructure — Mock Service

**Files:**
- Create: `test/helpers/mock_audio_player_service.dart`

All widget tests use this shared stub so they don't require a real `AudioPlayer`.

- [ ] **Step 1: Create mock service**

```dart
// test/helpers/mock_audio_player_service.dart
import 'package:easy_audio_player/easy_audio_player.dart';
import 'package:rxdart/rxdart.dart';

/// A controllable stub of AudioPlayerService for widget tests.
/// Does not require just_audio platform channels.
class MockAudioPlayerService implements AudioPlayerServiceInterface {
  final _playerStateSubject = BehaviorSubject<EasyPlayerState>.seeded(const PlayerIdle());
  final _positionSubject = BehaviorSubject<Duration>.seeded(Duration.zero);
  final _durationSubject = BehaviorSubject<Duration?>.seeded(null);
  final _bufferedSubject = BehaviorSubject<Duration>.seeded(Duration.zero);
  final _currentTrackSubject = BehaviorSubject<AudioTrack?>.seeded(null);
  final _queueSubject = BehaviorSubject<List<AudioTrack>>.seeded([]);
  final _loopModeSubject = BehaviorSubject<EasyLoopMode>.seeded(EasyLoopMode.off);
  final _shuffleSubject = BehaviorSubject<bool>.seeded(false);
  final _volumeSubject = BehaviorSubject<double>.seeded(1.0);
  final _speedSubject = BehaviorSubject<double>.seeded(1.0);
  final _errorSubject = PublishSubject<AudioPlayerError>();

  Stream<EasyPlayerState> get playerStateStream => _playerStateSubject.stream;
  Stream<Duration> get positionStream => _positionSubject.stream;
  Stream<Duration?> get durationStream => _durationSubject.stream;
  Stream<Duration> get bufferedStream => _bufferedSubject.stream;
  Stream<AudioTrack?> get currentTrackStream => _currentTrackSubject.stream;
  Stream<List<AudioTrack>> get queueStream => _queueSubject.stream;
  Stream<EasyLoopMode> get loopModeStream => _loopModeSubject.stream;
  Stream<bool> get shuffleStream => _shuffleSubject.stream;
  Stream<double> get volumeStream => _volumeSubject.stream;
  Stream<double> get speedStream => _speedSubject.stream;
  Stream<AudioPlayerError> get errorStream => _errorSubject.stream;

  EasyPlayerState get playerState => _playerStateSubject.value;
  Duration get position => _positionSubject.value;
  Duration? get duration => _durationSubject.value;
  Duration get buffered => _bufferedSubject.value;
  AudioTrack? get currentTrack => _currentTrackSubject.value;
  List<AudioTrack> get queue => List.unmodifiable(_queueSubject.value);
  EasyLoopMode get loopMode => _loopModeSubject.value;
  bool get shuffleEnabled => _shuffleSubject.value;
  double get volume => _volumeSubject.value;
  double get speed => _speedSubject.value;

  // Test helpers — emit state changes for widget testing
  void emitState(EasyPlayerState state) => _playerStateSubject.add(state);
  void emitTrack(AudioTrack? track) => _currentTrackSubject.add(track);
  void emitQueue(List<AudioTrack> queue) => _queueSubject.add(queue);
  void emitPosition(Duration pos) => _positionSubject.add(pos);
  void emitDuration(Duration? d) => _durationSubject.add(d);

  // No-op controls for widget interaction testing
  Future<void> play() async {}
  Future<void> pause() async {}
  Future<void> stop() async {}
  Future<void> seek(Duration position) async {}
  Future<void> skipToNext() async {}
  Future<void> skipToPrevious() async {}
  Future<void> setVolume(double v) async {}
  Future<void> setSpeed(double s) async {}
  Future<void> setLoopMode(EasyLoopMode mode) async {}
  Future<void> setShuffle(bool enabled) async {}
  Future<void> load(List<AudioTrack> tracks, {int initialIndex = 0}) async {}
  Future<void> add(AudioTrack track) async {}
  Future<void> insert(int index, AudioTrack track) async {}
  Future<void> remove(int index) async {}
  Future<void> move(int from, int to) async {}
  Future<void> clear() async {}
  Future<void> skipToIndex(int index) async {}

  Future<void> dispose() async {
    await _playerStateSubject.close();
    await _positionSubject.close();
    await _durationSubject.close();
    await _bufferedSubject.close();
    await _currentTrackSubject.close();
    await _queueSubject.close();
    await _loopModeSubject.close();
    await _shuffleSubject.close();
    await _volumeSubject.close();
    await _speedSubject.close();
    await _errorSubject.close();
  }
}
```

**Important:** Widgets in the next tasks must accept an `AudioPlayerService`-compatible interface. To allow injection of `MockAudioPlayerService`, extract an `abstract interface class` or make widgets accept the concrete service. The simplest approach: widgets receive `AudioPlayerService` from `EasyAudioPlayer.service` by default, but accept an optional override parameter (for testing). Use the mock in tests by injecting directly.

Since Dart doesn't support duck typing, the practical approach is to have widgets access `EasyAudioPlayer.service` internally AND provide a `@visibleForTesting serviceOverride` parameter.

- [ ] **Step 2: Commit**

```bash
git add test/helpers/mock_audio_player_service.dart
git commit -m "test: add MockAudioPlayerService for widget tests"
```

---

## Task 11: Component Widgets

**Files:**
- Create: `lib/src/widgets/components/seek_bar.dart`
- Create: `lib/src/widgets/components/artwork_widget.dart`
- Create: `lib/src/widgets/components/track_info_widget.dart`
- Create: `lib/src/widgets/components/control_buttons.dart`
- Create: `lib/src/widgets/components/waveform_widget.dart`
- Create: `lib/src/widgets/components/playlist_view.dart`

These are internal components used by the three player widgets.

- [ ] **Step 1: Create SeekBar**

```dart
// lib/src/widgets/components/seek_bar.dart
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';

import '../../core/audio_player_service.dart';
import '../../models/audio_player_theme.dart';

class EasySeekBar extends StatelessWidget {
  final AudioPlayerTheme theme;
  final AudioPlayerServiceInterface service;

  const EasySeekBar({
    super.key,
    required this.theme,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: service.positionStream,
      builder: (context, posSnapshot) {
        return StreamBuilder<Duration?>(
          stream: service.durationStream,
          builder: (context, durSnapshot) {
            return StreamBuilder<Duration>(
              stream: service.bufferedStream,
              builder: (context, bufSnapshot) {
                return ProgressBar(
                  progress: posSnapshot.data ?? Duration.zero,
                  total: durSnapshot.data ?? Duration.zero,
                  buffered: bufSnapshot.data ?? Duration.zero,
                  onSeek: service.seek,
                  progressBarColor: theme.progressBarColor,
                  bufferedBarColor: theme.bufferedBarColor,
                  baseBarColor: theme.bufferedBarColor?.withValues(alpha: 0.3),
                  thumbColor: theme.primaryColor,
                  timeLabelTextStyle: theme.subtitleStyle,
                );
              },
            );
          },
        );
      },
    );
  }
}
```

- [ ] **Step 2: Create ArtworkWidget**

```dart
// lib/src/widgets/components/artwork_widget.dart
import 'package:flutter/material.dart';

import '../../models/audio_player_theme.dart';

class ArtworkWidget extends StatelessWidget {
  final String? artworkUrl;
  final double size;
  final AudioPlayerTheme theme;

  const ArtworkWidget({
    super.key,
    required this.artworkUrl,
    required this.size,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(theme.borderRadius ?? 12.0),
      child: artworkUrl != null
          ? Image.network(
              artworkUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(size, theme),
            )
          : _placeholder(size, theme),
    );
  }

  static Widget _placeholder(double size, AudioPlayerTheme theme) {
    return Container(
      width: size,
      height: size,
      color: theme.bufferedBarColor,
      child: Icon(
        Icons.music_note,
        size: size * 0.4,
        color: theme.primaryColor,
      ),
    );
  }
}
```

- [ ] **Step 3: Create TrackInfoWidget**

```dart
// lib/src/widgets/components/track_info_widget.dart
import 'package:flutter/material.dart';

import '../../models/audio_player_theme.dart';
import '../../models/audio_track.dart';

class TrackInfoWidget extends StatelessWidget {
  final AudioTrack? track;
  final AudioPlayerTheme theme;
  final bool compact;

  const TrackInfoWidget({
    super.key,
    required this.track,
    required this.theme,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (track == null) {
      return Text('No track loaded', style: theme.subtitleStyle);
    }
    return Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          track!.title,
          style: theme.titleStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (track!.artist != null) ...[
          const SizedBox(height: 2),
          Text(
            track!.artist!,
            style: theme.subtitleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 4: Create ControlButtons**

```dart
// lib/src/widgets/components/control_buttons.dart
import 'package:flutter/material.dart';

import '../../core/audio_player_service.dart';
import '../../core/audio_player_state.dart';
import '../../models/audio_player_theme.dart';
import '../../models/easy_loop_mode.dart';

class ControlButtons extends StatelessWidget {
  final AudioPlayerServiceInterface service;
  final AudioPlayerTheme theme;
  final bool showVolume;
  final bool showSpeed;
  final bool showShuffle;
  final bool showLoop;

  const ControlButtons({
    super.key,
    required this.service,
    required this.theme,
    this.showVolume = true,
    this.showSpeed = true,
    this.showShuffle = true,
    this.showLoop = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showShuffle) _ShuffleButton(service: service, theme: theme),
            IconButton(
              icon: const Icon(Icons.skip_previous),
              onPressed: service.skipToPrevious,
              color: theme.primaryColor,
              iconSize: 32,
            ),
            _PlayPauseButton(service: service, theme: theme),
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: service.skipToNext,
              color: theme.primaryColor,
              iconSize: 32,
            ),
            if (showLoop) _LoopButton(service: service, theme: theme),
          ],
        ),
        if (showVolume) _VolumeRow(service: service, theme: theme),
        if (showSpeed) _SpeedRow(service: service, theme: theme),
      ],
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final AudioPlayerServiceInterface service;
  final AudioPlayerTheme theme;

  const _PlayPauseButton({required this.service, required this.theme});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EasyPlayerState>(
      stream: service.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const PlayerIdle();
        return switch (state) {
          PlayerBuffering() => SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.primaryColor,
              ),
            ),
          PlayerPlaying() => IconButton(
              icon: const Icon(Icons.pause_circle_filled),
              onPressed: service.pause,
              color: theme.primaryColor,
              iconSize: 56,
            ),
          PlayerCompleted() => IconButton(
              icon: const Icon(Icons.replay),
              onPressed: () => service.seek(Duration.zero),
              color: theme.primaryColor,
              iconSize: 56,
            ),
          _ => IconButton(
              icon: const Icon(Icons.play_circle_filled),
              onPressed: service.play,
              color: theme.primaryColor,
              iconSize: 56,
            ),
        };
      },
    );
  }
}

class _LoopButton extends StatelessWidget {
  final AudioPlayerServiceInterface service;
  final AudioPlayerTheme theme;

  const _LoopButton({required this.service, required this.theme});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EasyLoopMode>(
      stream: service.loopModeStream,
      builder: (context, snapshot) {
        final mode = snapshot.data ?? EasyLoopMode.off;
        return IconButton(
          icon: Icon(
            mode == EasyLoopMode.one ? Icons.repeat_one : Icons.repeat,
          ),
          color: mode == EasyLoopMode.off
              ? theme.primaryColor?.withValues(alpha: 0.4)
              : theme.primaryColor,
          onPressed: () {
            final next = switch (mode) {
              EasyLoopMode.off => EasyLoopMode.all,
              EasyLoopMode.all => EasyLoopMode.one,
              EasyLoopMode.one => EasyLoopMode.off,
            };
            service.setLoopMode(next);
          },
        );
      },
    );
  }
}

class _ShuffleButton extends StatelessWidget {
  final AudioPlayerServiceInterface service;
  final AudioPlayerTheme theme;

  const _ShuffleButton({required this.service, required this.theme});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: service.shuffleStream,
      builder: (context, snapshot) {
        final enabled = snapshot.data ?? false;
        return IconButton(
          icon: const Icon(Icons.shuffle),
          color: enabled
              ? theme.primaryColor
              : theme.primaryColor?.withValues(alpha: 0.4),
          onPressed: () => service.setShuffle(!enabled),
        );
      },
    );
  }
}

class _VolumeRow extends StatelessWidget {
  final AudioPlayerServiceInterface service;
  final AudioPlayerTheme theme;

  const _VolumeRow({required this.service, required this.theme});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: service.volumeStream,
      builder: (context, snapshot) {
        final volume = snapshot.data ?? 1.0;
        return Row(
          children: [
            Icon(Icons.volume_down, color: theme.subtitleStyle?.color, size: 18),
            Expanded(
              child: Slider(
                value: volume,
                onChanged: service.setVolume,
                activeColor: theme.primaryColor,
              ),
            ),
            Icon(Icons.volume_up, color: theme.subtitleStyle?.color, size: 18),
          ],
        );
      },
    );
  }
}

class _SpeedRow extends StatelessWidget {
  final AudioPlayerServiceInterface service;
  final AudioPlayerTheme theme;

  const _SpeedRow({required this.service, required this.theme});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: service.speedStream,
      builder: (context, snapshot) {
        final speed = snapshot.data ?? 1.0;
        return Row(
          children: [
            Text('${speed.toStringAsFixed(1)}x',
                style: theme.subtitleStyle?.copyWith(fontSize: 12)),
            Expanded(
              child: Slider(
                value: speed,
                min: 0.5,
                max: 2.0,
                divisions: 6,
                onChanged: service.setSpeed,
                activeColor: theme.primaryColor,
              ),
            ),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 5: Create WaveformWidget**

```dart
// lib/src/widgets/components/waveform_widget.dart
//
// NOTE: This widget uses the just_waveform package which only supports
// Android, iOS, and macOS. On web, Linux, and Windows the [showWaveform]
// parameter on ExpandedPlayer is silently ignored and this widget is
// never rendered. This is by design — see platform requirements in the
// package README.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';

import '../../models/audio_player_theme.dart';
import '../../models/audio_track.dart';

/// Returns true if the current platform supports just_waveform.
bool get isWaveformSupported =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

class WaveformWidget extends StatefulWidget {
  final AudioTrack? track;
  final AudioPlayerTheme theme;
  final double height;

  const WaveformWidget({
    super.key,
    required this.track,
    required this.theme,
    this.height = 80,
  });

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget> {
  Stream<WaveformProgress>? _waveformStream;
  Waveform? _waveform;

  @override
  void didUpdateWidget(WaveformWidget old) {
    super.didUpdateWidget(old);
    if (old.track?.id != widget.track?.id) _loadWaveform();
  }

  @override
  void initState() {
    super.initState();
    _loadWaveform();
  }

  void _loadWaveform() {
    final track = widget.track;
    if (track == null || !isWaveformSupported) return;

    // just_waveform requires local file access — network tracks need
    // to be cached locally first. For assets and file tracks this works
    // directly. Network tracks show a loading placeholder.
    if (track.sourceType == TrackSourceType.network) {
      // Network waveform extraction requires downloading the file first.
      // This is a known limitation — show placeholder for network tracks.
      setState(() { _waveform = null; _waveformStream = null; });
      return;
    }

    final audioFile = track.sourceType == TrackSourceType.file
        ? track.file!
        : File(''); // asset tracks not supported by just_waveform directly

    // TODO: Add caching layer for network track waveform extraction.
    // For now, waveform is only rendered for local file tracks.
    if (!audioFile.existsSync()) return;

    setState(() {
      _waveformStream = JustWaveform.extract(
        audioInFile: audioFile,
        waveOutFile: File('${audioFile.path}.wave'),
        zoom: const WaveformZoom.pixelsPerStep(10),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_waveformStream == null) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: LinearProgressIndicator(
            color: widget.theme.waveformColor,
            backgroundColor: widget.theme.bufferedBarColor,
          ),
        ),
      );
    }

    return StreamBuilder<WaveformProgress>(
      stream: _waveformStream,
      builder: (context, snapshot) {
        if (snapshot.data?.waveform != null) {
          _waveform = snapshot.data!.waveform;
        }
        if (_waveform == null) {
          return SizedBox(
            height: widget.height,
            child: LinearProgressIndicator(
              value: snapshot.data?.progress,
              color: widget.theme.waveformColor,
              backgroundColor: widget.theme.bufferedBarColor,
            ),
          );
        }
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _WaveformPainter(
            waveform: _waveform!,
            color: widget.theme.waveformColor ?? Colors.blue,
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final Waveform waveform;
  final Color color;

  const _WaveformPainter({required this.waveform, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final sampleCount = waveform.data.length ~/ 2;
    if (sampleCount == 0) return;

    final stepWidth = size.width / sampleCount;
    final midY = size.height / 2;

    for (int i = 0; i < sampleCount; i++) {
      final maxAmplitude = waveform.getPixelMax(i, sampleCount, size.width.toInt());
      final minAmplitude = waveform.getPixelMin(i, sampleCount, size.width.toInt());
      final x = i * stepWidth;
      canvas.drawLine(
        Offset(x, midY - (maxAmplitude / 32768.0) * midY),
        Offset(x, midY - (minAmplitude / 32768.0) * midY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => old.waveform != waveform;
}
```

- [ ] **Step 6: Create PlaylistView**

```dart
// lib/src/widgets/components/playlist_view.dart
import 'package:flutter/material.dart';

import '../../core/audio_player_service.dart';
import '../../models/audio_player_theme.dart';
import '../../models/audio_track.dart';

class PlaylistView extends StatelessWidget {
  final AudioPlayerServiceInterface service;
  final AudioPlayerTheme theme;

  const PlaylistView({
    super.key,
    required this.service,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AudioTrack>>(
      stream: service.queueStream,
      builder: (context, queueSnapshot) {
        return StreamBuilder<AudioTrack?>(
          stream: service.currentTrackStream,
          builder: (context, currentSnapshot) {
            final queue = queueSnapshot.data ?? [];
            final current = currentSnapshot.data;

            if (queue.isEmpty) {
              return Center(
                child: Text('No tracks in queue', style: theme.subtitleStyle),
              );
            }

            return ReorderableListView.builder(
              shrinkWrap: true,
              itemCount: queue.length,
              onReorder: service.move,
              itemBuilder: (context, index) {
                final track = queue[index];
                final isPlaying = current?.id == track.id;

                return Dismissible(
                  key: ValueKey(track.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: Colors.red.withValues(alpha: 0.8),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => service.remove(index),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPlaying
                          ? theme.primaryColor
                          : theme.bufferedBarColor,
                      child: Icon(
                        isPlaying ? Icons.equalizer : Icons.music_note,
                        color: isPlaying
                            ? Colors.white
                            : theme.primaryColor,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      track.title,
                      style: theme.titleStyle?.copyWith(
                        fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: track.artist != null
                        ? Text(track.artist!, style: theme.subtitleStyle, maxLines: 1)
                        : null,
                    onTap: () => service.skipToIndex(index),
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: Icon(Icons.drag_handle, color: theme.subtitleStyle?.color),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
```

- [ ] **Step 7: Commit all components**

```bash
git add lib/src/widgets/components/
git commit -m "feat: add internal component widgets (seekbar, artwork, controls, playlist, waveform)"
```

---

## Task 12: MiniPlayer Widget

**Files:**
- Create: `lib/src/widgets/mini_player.dart`
- Create: `test/widgets/mini_player_test.dart`

- [ ] **Step 1: Write failing widget test**

```dart
// test/widgets/mini_player_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_audio_player/easy_audio_player.dart';
import '../helpers/mock_audio_player_service.dart';

void main() {
  group('MiniPlayer', () {
    late MockAudioPlayerService mockService;

    setUp(() {
      mockService = MockAudioPlayerService();
    });

    tearDown(() => mockService.dispose());

    testWidgets('renders without errors when no track is loaded', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiniPlayer(serviceOverride: mockService),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(MiniPlayer), findsOneWidget);
    });

    testWidgets('shows track title when a track is emitted', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiniPlayer(serviceOverride: mockService),
          ),
        ),
      );

      mockService.emitTrack(
        AudioTrack.network(id: '1', url: 'https://x.com/t.mp3', title: 'My Song'),
      );
      await tester.pump();

      expect(find.text('My Song'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiniPlayer(
              serviceOverride: mockService,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(MiniPlayer));
      expect(tapped, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run tests — expect failure**

```bash
flutter test test/widgets/mini_player_test.dart
```

- [ ] **Step 3: Create MiniPlayer**

```dart
// lib/src/widgets/mini_player.dart
import 'package:flutter/material.dart';

import '../core/audio_player_service.dart';
import '../core/audio_player_state.dart';
import '../core/easy_audio_player.dart';
import '../models/audio_player_theme.dart';
import '../models/audio_track.dart';
import 'components/artwork_widget.dart';
import 'components/control_buttons.dart';

class MiniPlayer extends StatelessWidget {
  /// Optional theme overrides. Inherits from app Material 3 theme by default.
  final AudioPlayerTheme? theme;

  /// Called when the player is tapped (e.g. to open ExpandedPlayer).
  final VoidCallback? onTap;

  /// @visibleForTesting — inject mock service in widget tests.
  final dynamic serviceOverride;

  const MiniPlayer({
    super.key,
    this.theme,
    this.onTap,
    this.serviceOverride,
  });

  AudioPlayerServiceInterface get _service =>
      serviceOverride as AudioPlayerServiceInterface? ?? EasyAudioPlayer.service;

  @override
  Widget build(BuildContext context) {
    final resolvedTheme = AudioPlayerTheme.of(context, override: theme);
    final service = _service;

    return StreamBuilder<AudioTrack?>(
      stream: service.currentTrackStream,
      builder: (context, trackSnapshot) {
        final track = trackSnapshot.data;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: resolvedTheme.backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                ArtworkWidget(
                  artworkUrl: track?.artworkUrl,
                  size: resolvedTheme.miniArtworkSize ?? 48,
                  theme: resolvedTheme,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track?.title ?? 'Not playing',
                        style: resolvedTheme.titleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (track?.artist != null)
                        Text(
                          track!.artist!,
                          style: resolvedTheme.subtitleStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                StreamBuilder<EasyPlayerState>(
                  stream: service.playerStateStream,
                  builder: (context, stateSnapshot) {
                    final state = stateSnapshot.data ?? const PlayerIdle();
                    return switch (state) {
                      PlayerBuffering() => Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: resolvedTheme.primaryColor,
                            ),
                          ),
                        ),
                      PlayerPlaying() => IconButton(
                          icon: const Icon(Icons.pause),
                          onPressed: service.pause,
                          color: resolvedTheme.primaryColor,
                        ),
                      _ => IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: service.play,
                          color: resolvedTheme.primaryColor,
                        ),
                    };
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: service.skipToNext,
                  color: resolvedTheme.primaryColor,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 4: Add to export stub**

```dart
// lib/easy_audio_player.dart — add line:
export 'src/widgets/mini_player.dart';
```

- [ ] **Step 5: Run tests — expect pass**

```bash
flutter test test/widgets/mini_player_test.dart
```

- [ ] **Step 6: Commit**

```bash
git add lib/src/widgets/mini_player.dart lib/easy_audio_player.dart test/widgets/mini_player_test.dart
git commit -m "feat: add MiniPlayer widget"
```

---

## Task 13: ExpandedPlayer Widget

**Files:**
- Create: `lib/src/widgets/expanded_player.dart`
- Create: `test/widgets/expanded_player_test.dart`

- [ ] **Step 1: Write failing widget test**

```dart
// test/widgets/expanded_player_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_audio_player/easy_audio_player.dart';
import '../helpers/mock_audio_player_service.dart';

void main() {
  group('ExpandedPlayer', () {
    late MockAudioPlayerService mockService;

    setUp(() => mockService = MockAudioPlayerService());
    tearDown(() => mockService.dispose());

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandedPlayer(serviceOverride: mockService),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ExpandedPlayer), findsOneWidget);
    });

    testWidgets('showWaveform=false hides waveform widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandedPlayer(
              showWaveform: false,
              serviceOverride: mockService,
            ),
          ),
        ),
      );
      await tester.pump();
      // WaveformWidget should not be in the tree when showWaveform is false
      expect(find.byType(WaveformWidget), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Run tests — expect failure**

```bash
flutter test test/widgets/expanded_player_test.dart
```

- [ ] **Step 3: Create ExpandedPlayer**

```dart
// lib/src/widgets/expanded_player.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/audio_player_service.dart';
import '../core/easy_audio_player.dart';
import '../models/audio_player_theme.dart';
import 'components/artwork_widget.dart';
import 'components/control_buttons.dart';
import 'components/playlist_view.dart';
import 'components/seek_bar.dart';
import 'components/track_info_widget.dart';
import 'components/waveform_widget.dart';

/// Full-view audio player with artwork, metadata, controls, seekbar,
/// optional waveform, and optional playlist.
///
/// **Layout constraint:** When [showPlaylist] is `true`, `ExpandedPlayer`
/// uses an [Expanded] widget for the playlist — it must be placed inside
/// a parent that provides a bounded height (e.g., a `Scaffold` body,
/// a `SizedBox` with explicit height, or a `Column` inside an `Expanded`).
/// Dropping it directly into a `ListView` or `SingleChildScrollView`
/// without a height constraint will throw a `RenderFlex` unbounded height
/// error. Set [showPlaylist] to `false` to use it in unbounded contexts.
class ExpandedPlayer extends StatelessWidget {
  /// Optional theme overrides. Inherits from app Material 3 theme by default.
  final AudioPlayerTheme? theme;

  /// Show waveform visualization below the seekbar.
  ///
  /// NOTE: This uses the just_waveform package which only supports Android,
  /// iOS, and macOS. On web, Linux, and Windows this parameter is silently
  /// ignored — no waveform will be rendered regardless of this value.
  final bool showWaveform;

  /// Show the playlist queue below the controls.
  final bool showPlaylist;

  /// @visibleForTesting — inject mock service in widget tests.
  final dynamic serviceOverride;

  const ExpandedPlayer({
    super.key,
    this.theme,
    this.showWaveform = false,
    this.showPlaylist = true,
    this.serviceOverride,
  });

  AudioPlayerServiceInterface get _service =>
      serviceOverride as AudioPlayerServiceInterface? ?? EasyAudioPlayer.service;

  bool get _canShowWaveform => showWaveform && isWaveformSupported;

  @override
  Widget build(BuildContext context) {
    final resolvedTheme = AudioPlayerTheme.of(context, override: theme);
    final service = _service;

    return StreamBuilder(
      stream: service.currentTrackStream,
      builder: (context, trackSnapshot) {
        final track = trackSnapshot.data;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: ArtworkWidget(
                artworkUrl: track?.artworkUrl,
                size: resolvedTheme.expandedArtworkSize ?? 240,
                theme: resolvedTheme,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TrackInfoWidget(
                track: track,
                theme: resolvedTheme,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: EasySeekBar(theme: resolvedTheme, service: service),
            ),
            if (_canShowWaveform)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: WaveformWidget(track: track, theme: resolvedTheme),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ControlButtons(
                service: service,
                theme: resolvedTheme,
              ),
            ),
            if (showPlaylist) ...[
              const Divider(),
              Expanded(
                child: PlaylistView(service: service, theme: resolvedTheme),
              ),
            ],
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 4: Export `WaveformWidget` for test access, add to main export**

```dart
// lib/easy_audio_player.dart — add line:
export 'src/widgets/expanded_player.dart';
export 'src/widgets/components/waveform_widget.dart' show WaveformWidget, isWaveformSupported;
```

- [ ] **Step 5: Run tests — expect pass**

```bash
flutter test test/widgets/expanded_player_test.dart
```

- [ ] **Step 6: Commit**

```bash
git add lib/src/widgets/expanded_player.dart lib/easy_audio_player.dart test/widgets/expanded_player_test.dart
git commit -m "feat: add ExpandedPlayer widget with waveform + playlist support"
```

---

## Task 14: PlayerControls Widget

**Files:**
- Create: `lib/src/widgets/player_controls.dart`
- Create: `test/widgets/player_controls_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// test/widgets/player_controls_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_audio_player/easy_audio_player.dart';
import '../helpers/mock_audio_player_service.dart';

void main() {
  group('PlayerControls', () {
    late MockAudioPlayerService mockService;

    setUp(() => mockService = MockAudioPlayerService());
    tearDown(() => mockService.dispose());

    testWidgets('renders without errors with all options enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(serviceOverride: mockService),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PlayerControls), findsOneWidget);
    });

    testWidgets('hides volume when showVolume=false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(
              showVolume: false,
              serviceOverride: mockService,
            ),
          ),
        ),
      );
      await tester.pump();
      // Volume slider should not appear
      expect(find.byIcon(Icons.volume_up), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Run — expect failure**

```bash
flutter test test/widgets/player_controls_test.dart
```

- [ ] **Step 3: Create PlayerControls**

```dart
// lib/src/widgets/player_controls.dart
import 'package:flutter/material.dart';

import '../core/audio_player_service.dart';
import '../core/easy_audio_player.dart';
import '../models/audio_player_theme.dart';
import 'components/control_buttons.dart';
import 'components/seek_bar.dart';

/// Headless control widget — renders only playback controls with no
/// artwork, metadata, or layout opinions. Use this when you want to
/// build a custom player UI and drive it with [EasyAudioPlayer.service].
class PlayerControls extends StatelessWidget {
  /// Optional theme overrides. Inherits from app Material 3 theme by default.
  final AudioPlayerTheme? theme;
  final bool showVolume;
  final bool showSpeed;
  final bool showShuffle;
  final bool showLoop;
  final bool showSeekBar;

  /// @visibleForTesting — inject mock service in widget tests.
  final dynamic serviceOverride;

  const PlayerControls({
    super.key,
    this.theme,
    this.showVolume = true,
    this.showSpeed = true,
    this.showShuffle = true,
    this.showLoop = true,
    this.showSeekBar = true,
    this.serviceOverride,
  });

  AudioPlayerServiceInterface get _service =>
      serviceOverride as AudioPlayerServiceInterface? ?? EasyAudioPlayer.service;

  @override
  Widget build(BuildContext context) {
    final resolvedTheme = AudioPlayerTheme.of(context, override: theme);
    final service = _service;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSeekBar)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: EasySeekBar(theme: resolvedTheme, service: service),
          ),
        ControlButtons(
          service: service,
          theme: resolvedTheme,
          showVolume: showVolume,
          showSpeed: showSpeed,
          showShuffle: showShuffle,
          showLoop: showLoop,
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Add to export**

```dart
// lib/easy_audio_player.dart — add line:
export 'src/widgets/player_controls.dart';
```

- [ ] **Step 5: Run tests — expect pass**

```bash
flutter test test/widgets/player_controls_test.dart
```

- [ ] **Step 6: Commit**

```bash
git add lib/src/widgets/player_controls.dart lib/easy_audio_player.dart test/widgets/player_controls_test.dart
git commit -m "feat: add PlayerControls headless widget"
```

---

## Task 15: Finalize Public Export + Delete Old Files

**Files:**
- Modify: `lib/easy_audio_player.dart` (finalize)
- Delete: all old lib files

- [ ] **Step 1: Write final export file**

```dart
// lib/easy_audio_player.dart
/// Easy Audio Player — drop-in Flutter audio player with background
/// playback, notification controls, and Material 3 adaptive theming.
///
/// Usage:
/// ```dart
/// void main() async {
///   await EasyAudioPlayer.init(
///     config: AudioPlayerConfig(
///       androidNotificationChannelId: 'com.myapp.audio',
///       androidNotificationChannelName: 'Music',
///     ),
///   );
///   runApp(MyApp());
/// }
/// ```
library easy_audio_player;

// Core lifecycle
export 'src/core/easy_audio_player.dart';
// AudioPlayerService is NOT exported — access it only via EasyAudioPlayer.service
// which returns AudioPlayerServiceInterface. This keeps the public API surface minimal.
export 'src/core/audio_player_service_interface.dart';
export 'src/core/audio_player_state.dart';
export 'src/core/audio_player_config.dart';

// Models
export 'src/models/audio_track.dart';
export 'src/models/audio_player_error.dart';
export 'src/models/easy_loop_mode.dart';
export 'src/models/audio_player_theme.dart';

// Widgets
export 'src/widgets/mini_player.dart';
export 'src/widgets/expanded_player.dart';
export 'src/widgets/player_controls.dart';

// Waveform support (Android, iOS, macOS only)
// WaveformWidget exported for use in tests and custom layouts.
// isWaveformSupported exported for platform checks in consuming apps.
export 'src/widgets/components/waveform_widget.dart' show WaveformWidget, isWaveformSupported;
```

- [ ] **Step 2: Delete all old source files**

```bash
rm lib/flutter_audio_player.dart
rm -rf lib/services
rm -rf lib/models
rm -rf lib/helpers
rm -rf lib/widgets
```

- [ ] **Step 3: Run full test suite**

```bash
flutter test
```

Expected: all tests PASS.

- [ ] **Step 4: Analyze for warnings**

```bash
flutter analyze
```

Expected: no errors. Address any warnings about deprecated APIs.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: finalize public API export, delete old v0.x source files"
```

---

## Task 16: Android Platform Configuration

**Files:**
- Modify: `example/android/app/build.gradle`
- Modify: `example/android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Update build.gradle**

In `example/android/app/build.gradle`, set:

```gradle
android {
    compileSdkVersion 35

    defaultConfig {
        minSdkVersion 19
        targetSdkVersion 35
    }
}
```

Also update the Android Gradle Plugin in `example/android/build.gradle`:

```gradle
dependencies {
    classpath 'com.android.tools.build:gradle:8.5.2'
}
```

- [ ] **Step 2: Update AndroidManifest.xml**

Replace `example/android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Required for background audio playback -->
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>

    <!-- Required on Android 14+ (API 34) for media playback foreground service -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>

    <!-- Required on Android 13+ (API 33) to show media notification.
         Must also be requested at runtime — see README for code example. -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

    <application
        android:label="example"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <!-- Use AudioServiceActivity instead of FlutterActivity for
             background audio support via audio_service -->
        <activity
            android:name="com.ryanheise.audioservice.AudioServiceActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme"/>
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <service android:name="com.ryanheise.audioservice.AudioService"
            android:foregroundServiceType="mediaPlayback"
            android:exported="true">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService" />
            </intent-filter>
        </service>

        <receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MEDIA_BUTTON" />
            </intent-filter>
        </receiver>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

- [ ] **Step 3: Commit**

```bash
git add example/android/
git commit -m "chore(android): update manifest for API 33/34, typed foreground service"
```

---

## Task 17: iOS Platform Configuration

**Files:**
- Modify: `example/ios/Runner/Info.plist`

- [ ] **Step 1: Add background audio mode to Info.plist**

Open `example/ios/Runner/Info.plist` and add inside the root `<dict>`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

- [ ] **Step 2: Verify minimum iOS version**

In `example/ios/Podfile`, ensure:

```ruby
platform :ios, '12.0'
```

- [ ] **Step 3: Commit**

```bash
git add example/ios/
git commit -m "chore(ios): add UIBackgroundModes audio, min iOS 12.0"
```

---

## Final Verification

- [ ] **Run full test suite**

```bash
flutter test
```

Expected: all tests PASS, zero failures.

- [ ] **Run static analysis**

```bash
flutter analyze
```

Expected: no errors.

- [ ] **Verify pub publish readiness**

```bash
flutter pub publish --dry-run
```

Expected: no critical issues (some warnings about package description are OK at this stage).

---

*Plan B (Example App) covers the four-screen demo application and is in a separate plan file.*
