# easy_audio_player — Example App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
> **Prerequisite:** The core package plan (`2026-03-24-core-package.md`) must be complete before executing this plan.

**Goal:** Build a four-screen example app that demonstrates every capability of `easy_audio_player` — giving developers a runnable showcase and a copy-paste reference.

**Architecture:** A single `MaterialApp` with bottom `NavigationBar` (four tabs). All screens share the same `EasyAudioPlayer.service` singleton initialized in `main()`. Screens are stateless where possible — state lives in the service.

**Tech Stack:** Flutter 3.27+, easy_audio_player (path dep), Material 3 theming

---

## File Map

**Create:**
```
example/lib/main.dart                              ← init + 4-tab scaffold
example/lib/data/sample_tracks.dart               ← shared track list used by all screens
example/lib/screens/mini_player_screen.dart       ← Tab 1: MiniPlayer demo
example/lib/screens/expanded_player_screen.dart   ← Tab 2: ExpandedPlayer demo
example/lib/screens/player_controls_screen.dart   ← Tab 3: PlayerControls (custom UI)
example/lib/screens/features_screen.dart          ← Tab 4: error handling, loop, speed
```

**Modify:**
```
example/pubspec.yaml                              ← Dart 3, updated lints
```

---

## Task 1: Update example/pubspec.yaml

**Files:**
- Modify: `example/pubspec.yaml`

- [ ] **Step 1: Replace content**

```yaml
name: easy_audio_player_example
description: Demonstrates easy_audio_player package capabilities.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.27.0'

dependencies:
  flutter:
    sdk: flutter
  easy_audio_player:
    path: ../
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/audio/
```

- [ ] **Step 2: Create assets directory and add a bundled test track**

```bash
mkdir -p example/assets/audio
```

Download a short (< 30s) royalty-free MP3 into `example/assets/audio/sample.mp3`. A suitable source: https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3 (save first 30s). Alternatively, generate a silent MP3 with ffmpeg:

```bash
ffmpeg -f lavfi -i anullsrc=r=44100:cl=stereo -t 10 -q:a 9 -acodec libmp3lame example/assets/audio/sample.mp3
```

- [ ] **Step 3: Get dependencies**

```bash
cd example && flutter pub get
```

- [ ] **Step 4: Commit**

```bash
git add example/pubspec.yaml example/assets/
git commit -m "chore(example): update to dart3, add assets"
```

---

## Task 2: Sample Track Data

**Files:**
- Create: `example/lib/data/sample_tracks.dart`

Shared track list used by all four screens so they always have something to play.

- [ ] **Step 1: Create sample tracks**

```dart
// example/lib/data/sample_tracks.dart
import 'package:easy_audio_player/easy_audio_player.dart';

/// Sample tracks used across all example screens.
/// Mix of network, asset, and an intentionally broken URL for error demos.
final sampleTracks = [
  AudioTrack.network(
    id: 'track_1',
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    title: 'SoundHelix Song 1',
    artist: 'SoundHelix',
    album: 'Sample Album',
    artworkUrl: 'https://picsum.photos/seed/track1/300/300',
    extras: {'genre': 'Electronic'},
  ),
  AudioTrack.network(
    id: 'track_2',
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    title: 'SoundHelix Song 2',
    artist: 'SoundHelix',
    album: 'Sample Album',
    artworkUrl: 'https://picsum.photos/seed/track2/300/300',
  ),
  AudioTrack.asset(
    id: 'track_asset',
    assetPath: 'assets/audio/sample.mp3',
    title: 'Bundled Asset Track',
    artist: 'Local',
    album: 'Device',
    artworkUrl: 'https://picsum.photos/seed/asset/300/300',
  ),
  AudioTrack.network(
    id: 'track_3',
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    title: 'SoundHelix Song 3',
    artist: 'SoundHelix',
    album: 'Sample Album',
    artworkUrl: 'https://picsum.photos/seed/track3/300/300',
  ),
];

/// A broken track used in the Features screen to demonstrate error handling.
final brokenTrack = AudioTrack.network(
  id: 'track_broken',
  url: 'https://example.com/this-file-does-not-exist.mp3',
  title: 'Broken Track (404)',
  artist: 'Error Demo',
  artworkUrl: 'https://picsum.photos/seed/broken/300/300',
);
```

- [ ] **Step 2: Commit**

```bash
git add example/lib/data/sample_tracks.dart
git commit -m "feat(example): add sample track data"
```

---

## Task 3: Main App Shell

**Files:**
- Create: `example/lib/main.dart`

- [ ] **Step 1: Create main.dart**

```dart
// example/lib/main.dart
import 'package:easy_audio_player/easy_audio_player.dart';
import 'package:flutter/material.dart';

import 'screens/expanded_player_screen.dart';
import 'screens/features_screen.dart';
import 'screens/mini_player_screen.dart';
import 'screens/player_controls_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyAudioPlayer.init(
    config: const AudioPlayerConfig(
      androidNotificationChannelId: 'com.example.easy_audio_player',
      androidNotificationChannelName: 'Easy Audio Player',
    ),
  );

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'easy_audio_player Demo',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final _screens = const [
    MiniPlayerScreen(),
    ExpandedPlayerScreen(),
    PlayerControlsScreen(),
    FeaturesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Mini',
          ),
          NavigationDestination(
            icon: Icon(Icons.music_note),
            label: 'Expanded',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune),
            label: 'Controls',
          ),
          NavigationDestination(
            icon: Icon(Icons.science_outlined),
            label: 'Features',
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add example/lib/main.dart
git commit -m "feat(example): add 4-tab app shell with M3 theme"
```

---

## Task 4: Tab 1 — MiniPlayerScreen

**Files:**
- Create: `example/lib/screens/mini_player_screen.dart`

Demonstrates `MiniPlayer` pinned at the bottom with a scrollable track list above it. Tapping a track in the list loads the full playlist starting at that track. Tapping the mini player itself does nothing in this demo (shows a SnackBar hint to see the Expanded tab).

- [ ] **Step 1: Create screen**

```dart
// example/lib/screens/mini_player_screen.dart
import 'dart:async';

import 'package:easy_audio_player/easy_audio_player.dart';
import 'package:flutter/material.dart';

import '../data/sample_tracks.dart';

class MiniPlayerScreen extends StatelessWidget {
  const MiniPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MiniPlayer')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: sampleTracks.length,
              itemBuilder: (context, index) {
                final track = sampleTracks[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: track.artworkUrl != null
                        ? NetworkImage(track.artworkUrl!)
                        : null,
                    child: track.artworkUrl == null
                        ? const Icon(Icons.music_note)
                        : null,
                  ),
                  title: Text(track.title),
                  subtitle: Text(track.artist ?? ''),
                  onTap: () {
                    unawaited(EasyAudioPlayer.service.load(
                      sampleTracks,
                      initialIndex: index,
                    ));
                    unawaited(EasyAudioPlayer.service.play());
                  },
                );
              },
            ),
          ),
          MiniPlayer(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Switch to the Expanded tab for the full player'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add example/lib/screens/mini_player_screen.dart
git commit -m "feat(example): add MiniPlayer screen (Tab 1)"
```

---

## Task 5: Tab 2 — ExpandedPlayerScreen

**Files:**
- Create: `example/lib/screens/expanded_player_screen.dart`

Demonstrates `ExpandedPlayer` with a toggle for waveform display. Shows the waveform note when on an unsupported platform.

- [ ] **Step 1: Create screen**

```dart
// example/lib/screens/expanded_player_screen.dart
import 'package:easy_audio_player/easy_audio_player.dart';
import 'package:flutter/material.dart';

import '../data/sample_tracks.dart';

class ExpandedPlayerScreen extends StatefulWidget {
  const ExpandedPlayerScreen({super.key});

  @override
  State<ExpandedPlayerScreen> createState() => _ExpandedPlayerScreenState();
}

class _ExpandedPlayerScreenState extends State<ExpandedPlayerScreen> {
  bool _showWaveform = false;
  bool _loaded = false;

  void _loadIfNeeded() {
    if (!_loaded) {
      EasyAudioPlayer.service.load(sampleTracks);
      _loaded = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ExpandedPlayer'),
        actions: [
          Tooltip(
            message: isWaveformSupported
                ? 'Toggle waveform'
                : 'Waveform not supported on this platform',
            child: Row(
              children: [
                const Icon(Icons.graphic_eq, size: 18),
                Switch(
                  value: _showWaveform && isWaveformSupported,
                  onChanged: isWaveformSupported
                      ? (v) => setState(() => _showWaveform = v)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
      body: ExpandedPlayer(
        showWaveform: _showWaveform,
        showPlaylist: true,
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add example/lib/screens/expanded_player_screen.dart
git commit -m "feat(example): add ExpandedPlayer screen with waveform toggle (Tab 2)"
```

---

## Task 6: Tab 3 — PlayerControlsScreen

**Files:**
- Create: `example/lib/screens/player_controls_screen.dart`

Demonstrates `PlayerControls` (headless) dropped into a custom-built layout. Shows how a developer would use the service directly alongside the controls widget.

- [ ] **Step 1: Create screen**

```dart
// example/lib/screens/player_controls_screen.dart
import 'dart:async';

import 'package:easy_audio_player/easy_audio_player.dart';
import 'package:flutter/material.dart';

import '../data/sample_tracks.dart';

/// Demonstrates using PlayerControls in a completely custom layout.
/// The artwork, title, and track info are built manually using
/// EasyAudioPlayer.service streams — showing how to go headless.
class PlayerControlsScreen extends StatelessWidget {
  const PlayerControlsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = EasyAudioPlayer.service;

    return Scaffold(
      appBar: AppBar(title: const Text('Custom UI with PlayerControls')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom-built "now playing" area using service streams directly
            Text('Now Playing', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            StreamBuilder<AudioTrack?>(
              stream: service.currentTrackStream,
              builder: (context, snapshot) {
                final track = snapshot.data;
                return Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: track?.artworkUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(track!.artworkUrl!, fit: BoxFit.cover),
                            )
                          : Icon(
                              Icons.music_note,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track?.title ?? 'No track loaded',
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (track?.artist != null)
                            Text(
                              track!.artist!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Drop-in PlayerControls — no artwork, no metadata, just controls
            const PlayerControls(
              showVolume: true,
              showSpeed: true,
              showShuffle: true,
              showLoop: true,
              showSeekBar: true,
            ),

            const SizedBox(height: 32),

            // Load the sample playlist button
            OutlinedButton.icon(
              icon: const Icon(Icons.playlist_play),
              label: const Text('Load sample playlist'),
              onPressed: () {
                unawaited(service.load(sampleTracks));
                unawaited(service.play());
              },
            ),

            const SizedBox(height: 8),
            Text(
              'This screen shows PlayerControls in a hand-crafted layout.\n'
              'The artwork and track info above are built manually using\n'
              'EasyAudioPlayer.service.currentTrackStream.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add example/lib/screens/player_controls_screen.dart
git commit -m "feat(example): add PlayerControls custom layout screen (Tab 3)"
```

---

## Task 7: Tab 4 — FeaturesScreen

**Files:**
- Create: `example/lib/screens/features_screen.dart`

Demonstrates: error handling (bad URL → SnackBar via `errorStream`), local asset playback, loop mode cycling, shuffle toggle, speed control.

- [ ] **Step 1: Create screen**

```dart
// example/lib/screens/features_screen.dart
import 'dart:async';

import 'package:easy_audio_player/easy_audio_player.dart';
import 'package:flutter/material.dart';

import '../data/sample_tracks.dart';

class FeaturesScreen extends StatefulWidget {
  const FeaturesScreen({super.key});

  @override
  State<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends State<FeaturesScreen> {
  StreamSubscription<AudioPlayerError>? _errorSub;

  @override
  void initState() {
    super.initState();
    // Subscribe to errorStream to show SnackBars on track failures.
    // Subscription is stored and cancelled in dispose() to prevent leaks.
    _errorSub = EasyAudioPlayer.service.errorStream.listen((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Track failed: "${error.trackId}" — ${error.message}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  @override
  void dispose() {
    _errorSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = EasyAudioPlayer.service;

    return Scaffold(
      appBar: AppBar(title: const Text('Features')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('Error Handling'),
          ListTile(
            leading: const Icon(Icons.error_outline, color: Colors.red),
            title: const Text('Load broken URL'),
            subtitle: const Text(
              'Loads a 404 track — the player auto-skips and shows a SnackBar',
            ),
            trailing: FilledButton(
              onPressed: () {
                unawaited(service.load([brokenTrack, ...sampleTracks]));
                unawaited(service.play());
              },
              child: const Text('Test'),
            ),
          ),

          const Divider(),
          _SectionHeader('Asset Playback'),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Play bundled asset'),
            subtitle: const Text('Plays assets/audio/sample.mp3'),
            trailing: FilledButton.tonal(
              onPressed: () {
                service.load([
                  AudioTrack.asset(
                    id: 'asset_demo',
                    assetPath: 'assets/audio/sample.mp3',
                    title: 'Bundled Asset Track',
                    artist: 'Local',
                  ),
                ]);
                service.play();
              },
              child: const Text('Play'),
            ),
          ),

          const Divider(),
          _SectionHeader('Loop Mode'),
          StreamBuilder<EasyLoopMode>(
            stream: service.loopModeStream,
            builder: (context, snapshot) {
              final mode = snapshot.data ?? EasyLoopMode.off;
              return ListTile(
                leading: Icon(
                  mode == EasyLoopMode.one ? Icons.repeat_one : Icons.repeat,
                ),
                title: Text('Loop: ${mode.name.toUpperCase()}'),
                subtitle: const Text('Tap to cycle: off → all → one → off'),
                trailing: FilledButton.tonal(
                  onPressed: () {
                    final next = switch (mode) {
                      EasyLoopMode.off => EasyLoopMode.all,
                      EasyLoopMode.all => EasyLoopMode.one,
                      EasyLoopMode.one => EasyLoopMode.off,
                    };
                    service.setLoopMode(next);
                  },
                  child: const Text('Cycle'),
                ),
              );
            },
          ),

          const Divider(),
          _SectionHeader('Shuffle'),
          StreamBuilder<bool>(
            stream: service.shuffleStream,
            builder: (context, snapshot) {
              final enabled = snapshot.data ?? false;
              return SwitchListTile(
                secondary: const Icon(Icons.shuffle),
                title: Text('Shuffle: ${enabled ? "ON" : "OFF"}'),
                subtitle: const Text('Randomizes playback order'),
                value: enabled,
                onChanged: service.setShuffle,
              );
            },
          ),

          const Divider(),
          _SectionHeader('Playback Speed'),
          StreamBuilder<double>(
            stream: service.speedStream,
            builder: (context, snapshot) {
              final speed = snapshot.data ?? 1.0;
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.speed),
                    title: Text('Speed: ${speed.toStringAsFixed(1)}x'),
                  ),
                  Slider(
                    value: speed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 6,
                    label: '${speed.toStringAsFixed(1)}x',
                    onChanged: service.setSpeed,
                  ),
                ],
              );
            },
          ),

          const Divider(),
          _SectionHeader('Playlist Management'),
          ListTile(
            leading: const Icon(Icons.queue_music),
            title: const Text('Load full sample playlist'),
            trailing: FilledButton.tonal(
              onPressed: () {
                unawaited(service.load(sampleTracks));
                unawaited(service.play());
              },
              child: const Text('Load'),
            ),
          ),
          StreamBuilder<List<AudioTrack>>(
            stream: service.queueStream,
            builder: (context, snapshot) {
              final queue = snapshot.data ?? [];
              if (queue.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
                    child: Text(
                      '${queue.length} track(s) in queue',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  ...queue.asMap().entries.map((entry) => ListTile(
                        dense: true,
                        leading: Text('${entry.key + 1}'),
                        title: Text(entry.value.title, maxLines: 1),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 18),
                          onPressed: () => service.remove(entry.key),
                        ),
                      )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add example/lib/screens/features_screen.dart
git commit -m "feat(example): add Features screen with error, asset, loop, shuffle, speed (Tab 4)"
```

---

## Final Verification

- [ ] **Analyze example**

```bash
cd example && flutter analyze
```

Expected: no errors.

- [ ] **Run on Android device or emulator (API 33+ preferred)**

```bash
cd example && flutter run
```

Verify:
- All 4 tabs navigate correctly
- Tracks play from network
- Asset track plays (Tab 4)
- Error SnackBar appears when broken track is loaded (Tab 4)
- Background playback continues when app is minimized
- Notification appears with track info and controls
- Lock screen controls work
- Waveform toggle appears in Tab 2 (greyed out on unsupported platforms)

- [ ] **Run on iOS device or simulator**

```bash
cd example && flutter run -d <ios-device-id>
```

Verify: same checklist as Android.

- [ ] **Final commit**

```bash
git add -A
git commit -m "feat(example): complete 4-screen demo app"
```
