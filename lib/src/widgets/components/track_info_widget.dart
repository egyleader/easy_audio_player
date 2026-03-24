// lib/src/widgets/components/track_info_widget.dart
import 'package:flutter/material.dart';

import '../../models/audio_track.dart';
import '../../models/audio_player_theme.dart';

class TrackInfoWidget extends StatelessWidget {
  final AudioTrack? track;
  final AudioPlayerTheme theme;
  final bool compact;

  const TrackInfoWidget({
    super.key,
    required this.track,
    required this.theme,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (track == null) {
      return Text('No track loaded', style: theme.subtitleStyle);
    }
    return Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          track!.title,
          style: theme.titleStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (track!.artist != null) ...[
          const SizedBox(height: 2),
          Text(
            track!.artist!,
            style: theme.subtitleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
