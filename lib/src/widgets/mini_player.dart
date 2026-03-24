// lib/src/widgets/mini_player.dart
import 'package:flutter/material.dart';

import '../core/audio_player_service_interface.dart';
import '../core/easy_audio_player.dart';
import '../models/audio_player_theme.dart';
import '../models/audio_track.dart';
import '../core/audio_player_state.dart';
import 'components/artwork_widget.dart';
import 'components/track_info_widget.dart';

/// A compact audio player pinned at the bottom of the screen.
///
/// Shows current track artwork, title/artist, and play/pause + skip controls.
/// Wrap in a [Column] or use [Scaffold.bottomNavigationBar] to pin it.
///
/// ```dart
/// Scaffold(
///   body: Column(children: [
///     Expanded(child: MyContent()),
///     const MiniPlayer(),
///   ]),
/// )
/// ```
class MiniPlayer extends StatelessWidget {
  /// Optional theme overrides. Inherits from app Material 3 theme by default.
  final AudioPlayerTheme? theme;

  /// Called when the user taps the player body (not a button).
  final VoidCallback? onTap;

  /// Override the service for testing. Defaults to [EasyAudioPlayer.service].
  final AudioPlayerServiceInterface? serviceOverride;

  const MiniPlayer({
    super.key,
    this.theme,
    this.onTap,
    this.serviceOverride,
  });

  @override
  Widget build(BuildContext context) {
    final service = serviceOverride ?? EasyAudioPlayer.service;
    final resolvedTheme = AudioPlayerTheme.of(context, override: theme);

    return StreamBuilder<AudioTrack?>(
      stream: service.currentTrackStream,
      builder: (context, trackSnapshot) {
        final track = trackSnapshot.data;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: resolvedTheme.backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                ArtworkWidget(
                  artworkUrl: track?.artworkUrl,
                  size: resolvedTheme.miniArtworkSize ?? 48,
                  theme: resolvedTheme,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrackInfoWidget(
                        track: track,
                        theme: resolvedTheme,
                        compact: true,
                      ),
                    ],
                  ),
                ),
                // Play/Pause button
                StreamBuilder<EasyPlayerState>(
                  stream: service.playerStateStream,
                  builder: (context, stateSnapshot) {
                    final state = stateSnapshot.data ?? const PlayerIdle();
                    return switch (state) {
                      PlayerBuffering() => Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: resolvedTheme.primaryColor,
                            ),
                          ),
                        ),
                      PlayerPlaying() => IconButton(
                          icon: const Icon(Icons.pause),
                          onPressed: service.pause,
                          color: resolvedTheme.primaryColor,
                        ),
                      _ => IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: service.play,
                          color: resolvedTheme.primaryColor,
                        ),
                    };
                  },
                ),
                // Skip next button
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: service.skipToNext,
                  color: resolvedTheme.primaryColor,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}
