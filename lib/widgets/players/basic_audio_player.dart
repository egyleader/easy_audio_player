import 'package:flutter/material.dart';
import 'package:flutter_audioplayer/flutter_audioplayer.dart';
import 'package:flutter_audioplayer/widgets/players/minimal_audio_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_audioplayer/services/audio_player_service.dart';
import 'package:flutter_audioplayer/widgets/buttons/control_buttons.dart';
import 'package:flutter_audioplayer/widgets/seekbar.dart';

class BasicAudioPlayer extends StatelessWidget {
  const BasicAudioPlayer({Key? key, required this.playlist, this.autoPlay = true}) : super(key: key);
  final ConcatenatingAudioSource playlist;
  final bool autoPlay;

  @override
  Widget build(BuildContext context) {
    final _audioPlayer = AudioPlayerService();
    return MinimalAudioPlayer(
      audioPlayer: _audioPlayer,
      autoPlay: autoPlay,
      playlist: playlist,
      child: Column(
        children: [
          ControlButtons(_audioPlayer.player),
          AudioPlayerSeekBar(audioPlayer: _audioPlayer),
          const SizedBox(height: 8.0),
        ],
      ),
    );
  }
}
