// lib/src/widgets/components/seek_bar.dart
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';

import '../../core/audio_player_service_interface.dart';
import '../../models/audio_player_theme.dart';

class EasySeekBar extends StatelessWidget {
  final AudioPlayerTheme theme;
  final AudioPlayerServiceInterface service;

  const EasySeekBar({super.key, required this.theme, required this.service});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: service.positionStream,
      builder: (context, posSnapshot) {
        return StreamBuilder<Duration?>(
          stream: service.durationStream,
          builder: (context, durSnapshot) {
            return StreamBuilder<Duration>(
              stream: service.bufferedStream,
              builder: (context, bufSnapshot) {
                return ProgressBar(
                  progress: posSnapshot.data ?? Duration.zero,
                  total: durSnapshot.data ?? Duration.zero,
                  buffered: bufSnapshot.data ?? Duration.zero,
                  onSeek: service.seek,
                  progressBarColor: theme.progressBarColor,
                  bufferedBarColor: theme.bufferedBarColor,
                  baseBarColor: theme.bufferedBarColor?.withValues(alpha: 0.3),
                  thumbColor: theme.primaryColor,
                  timeLabelTextStyle: theme.subtitleStyle,
                );
              },
            );
          },
        );
      },
    );
  }
}
