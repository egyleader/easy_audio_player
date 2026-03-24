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
