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
