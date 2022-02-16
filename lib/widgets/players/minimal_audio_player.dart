import 'package:easy_audio_player/flutter_audio_player.dart';
import 'package:easy_audio_player/widgets/buttons/play_button.dart';
import 'package:flutter/material.dart';
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
