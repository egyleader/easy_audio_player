// lib/src/widgets/expanded_player.dart
import 'package:flutter/material.dart';

import '../core/audio_player_service_interface.dart';
import '../core/easy_audio_player.dart';
import '../models/audio_player_theme.dart';
import '../models/audio_track.dart';
import 'components/artwork_widget.dart';
import 'components/control_buttons.dart';
import 'components/playlist_view.dart';
import 'components/seek_bar.dart';
import 'components/track_info_widget.dart';
import 'components/waveform_widget.dart';

/// Full-view audio player with artwork, metadata, controls, seekbar,
/// optional waveform, and optional playlist.
///
/// **Layout constraint:** When [showPlaylist] is `true`, `ExpandedPlayer`
/// uses an [Expanded] widget for the playlist — it must be placed inside
/// a parent that provides a bounded height (e.g., a `Scaffold` body,
/// a `SizedBox` with explicit height, or a `Column` inside an `Expanded`).
/// Dropping it directly into a `ListView` or `SingleChildScrollView`
/// without a height constraint will throw a `RenderFlex` unbounded height
/// error. Set [showPlaylist] to `false` to use it in unbounded contexts.
class ExpandedPlayer extends StatelessWidget {
  /// Optional theme overrides. Inherits from app Material 3 theme by default.
  final AudioPlayerTheme? theme;

  /// Shows the waveform below the seek bar. Only works on Android, iOS, macOS.
  /// Silently ignored on web, Linux, Windows.
  final bool showWaveform;

  /// Shows the playlist below the controls.
  final bool showPlaylist;

  /// Override the service for testing. Defaults to [EasyAudioPlayer.service].
  final AudioPlayerServiceInterface? serviceOverride;

  const ExpandedPlayer({
    super.key,
    this.theme,
    this.showWaveform = false,
    this.showPlaylist = false,
    this.serviceOverride,
  });

  bool get _canShowWaveform => showWaveform && isWaveformSupported;

  @override
  Widget build(BuildContext context) {
    final service = serviceOverride ?? EasyAudioPlayer.service;
    final resolvedTheme = AudioPlayerTheme.of(context, override: theme);

    return StreamBuilder<AudioTrack?>(
      stream: service.currentTrackStream,
      builder: (context, trackSnapshot) {
        final track = trackSnapshot.data;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: ArtworkWidget(
                artworkUrl: track?.artworkUrl,
                size: resolvedTheme.expandedArtworkSize ?? 240,
                theme: resolvedTheme,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TrackInfoWidget(
                track: track,
                theme: resolvedTheme,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: EasySeekBar(theme: resolvedTheme, service: service),
            ),
            if (_canShowWaveform)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: WaveformWidget(track: track, theme: resolvedTheme),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ControlButtons(
                service: service,
                theme: resolvedTheme,
              ),
            ),
            if (showPlaylist) ...[
              const Divider(),
              Expanded(
                child: PlaylistView(service: service, theme: resolvedTheme),
              ),
            ],
          ],
        );
      },
    );
  }
}
