// lib/src/widgets/components/playlist_view.dart
import 'package:flutter/material.dart';

import '../../core/audio_player_service_interface.dart';
import '../../models/audio_player_theme.dart';
import '../../models/audio_track.dart';

class PlaylistView extends StatelessWidget {
  final AudioPlayerServiceInterface service;
  final AudioPlayerTheme theme;

  const PlaylistView({super.key, required this.service, required this.theme});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AudioTrack>>(
      stream: service.queueStream,
      builder: (context, queueSnapshot) {
        return StreamBuilder<AudioTrack?>(
          stream: service.currentTrackStream,
          builder: (context, currentSnapshot) {
            final queue = queueSnapshot.data ?? [];
            final current = currentSnapshot.data;

            if (queue.isEmpty) {
              return Center(
                child: Text('No tracks', style: theme.subtitleStyle),
              );
            }

            return ReorderableListView.builder(
              shrinkWrap: true,
              itemCount: queue.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                service.move(oldIndex, newIndex);
              },
              itemBuilder: (context, i) {
                final track = queue[i];
                final isCurrent = track.id == current?.id;
                return Dismissible(
                  key: ValueKey(track.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => service.remove(i),
                  child: ListTile(
                    leading: Text(
                      '${i + 1}',
                      style: theme.subtitleStyle?.copyWith(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    title: Text(
                      track.title,
                      style: theme.titleStyle?.copyWith(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: track.artist != null
                        ? Text(track.artist!, style: theme.subtitleStyle, maxLines: 1)
                        : null,
                    trailing: ReorderableDragStartListener(
                      index: i,
                      child: const Icon(Icons.drag_handle),
                    ),
                    selected: isCurrent,
                    onTap: () => service.skipToIndex(i),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
