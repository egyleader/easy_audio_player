import 'package:flutter/material.dart';
import 'package:flutter_audioplayer/services/audio_player_service.dart';
import 'package:flutter_audioplayer/widgets/buttons/play_button.dart';
import 'package:just_audio/just_audio.dart';

class MinimalAudioPlayer extends StatelessWidget {
  const MinimalAudioPlayer(
      {Key? key, required this.audioPlayer, required this.playlist, this.autoPlay = true, this.child})
      : super(key: key);
  final AudioPlayerService audioPlayer;
  final ConcatenatingAudioSource playlist;
  final bool autoPlay;
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    audioPlayer.playAudios(playlist);
    if (autoPlay == false && child == null) return PlayButton(player: audioPlayer.player);
    return child ?? const SizedBox();
  }
}
