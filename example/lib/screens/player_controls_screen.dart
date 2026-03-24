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
