import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_player/flutter_audioplayer.dart';

class AudioPlayerSeekBar extends StatelessWidget {
  const AudioPlayerSeekBar({Key? key, required this.audioPlayer}) : super(key: key);
  final AudioPlayerService audioPlayer;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Object>(
        stream: audioPlayer.player.positionStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          var position = snapshot.data as Duration;
          return ProgressBar(
              progress: position,
              buffered: audioPlayer.player.playbackEvent.bufferedPosition,
              total: audioPlayer.player.playbackEvent.duration ?? Duration.zero,
              onSeek: audioPlayer.player.seek);
        });
  }
}
