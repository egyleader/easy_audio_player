import 'package:flutter/material.dart';
import 'package:flutter_audioplayer/widgets/play_list_View.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter_audioplayer/services/audio_player_service.dart';
import 'package:flutter_audioplayer/widgets/buttons/control_buttons.dart';
import 'package:flutter_audioplayer/widgets/buttons/loop_button.dart';
import 'package:flutter_audioplayer/widgets/buttons/shuffle_button.dart';
import 'package:flutter_audioplayer/widgets/players/minimal_audio_player.dart';
import 'package:flutter_audioplayer/widgets/seekbar.dart';

class FullAudioPlayer extends StatelessWidget {
  const FullAudioPlayer({Key? key, required this.playlist, this.autoPlay = true}) : super(key: key);
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
          Expanded(
            child: StreamBuilder<SequenceState?>(
              stream: _audioPlayer.player.sequenceStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                if (state?.sequence.isEmpty ?? true) return const SizedBox();
                final metadata = state!.currentSource!.tag as MediaItem;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(child: Image.network(metadata.artUri.toString())),
                      ),
                    ),
                    //? title and album
                    Text(metadata.title, style: Theme.of(context).textTheme.headline6),
                    Text(metadata.album ?? ''),
                  ],
                );
              },
            ),
          ),
          ControlButtons(_audioPlayer.player),
          AudioPlayerSeekBar(audioPlayer: _audioPlayer),
          const SizedBox(height: 8.0),
          Row(
            children: [
              LoopButton(player: _audioPlayer.player),
              Expanded(
                child: Text(
                  "Playlist",
                  style: Theme.of(context).textTheme.headline6,
                  textAlign: TextAlign.center,
                ),
              ),
              ShuffleButton(player: _audioPlayer.player)
            ],
          ),
          PlaylistView(player: _audioPlayer.player, playlist: playlist)
        ],
      ),
    );
  }
}
