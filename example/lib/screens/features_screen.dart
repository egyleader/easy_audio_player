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
                unawaited(service.load([
                  AudioTrack.asset(
                    id: 'asset_demo',
                    assetPath: 'assets/audio/sample.mp3',
                    title: 'Bundled Asset Track',
                    artist: 'Local',
                  ),
                ]));
                unawaited(service.play());
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
