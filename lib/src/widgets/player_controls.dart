// lib/src/widgets/player_controls.dart
import 'package:flutter/material.dart';

import '../core/audio_player_service_interface.dart';
import '../core/easy_audio_player.dart';
import '../models/audio_player_theme.dart';
import 'components/control_buttons.dart';
import 'components/seek_bar.dart';

/// Headless control widget — renders only playback controls with no
/// artwork, metadata, or layout opinions. Use this when you want to
/// build a custom player UI and drive it with [EasyAudioPlayer.service].
class PlayerControls extends StatelessWidget {
  /// Optional theme overrides. Inherits from app Material 3 theme by default.
  final AudioPlayerTheme? theme;
  final bool showVolume;
  final bool showSpeed;
  final bool showShuffle;
  final bool showLoop;
  final bool showSeekBar;

  /// @visibleForTesting — inject mock service in widget tests.
  final AudioPlayerServiceInterface? serviceOverride;

  const PlayerControls({
    super.key,
    this.theme,
    this.showVolume = true,
    this.showSpeed = true,
    this.showShuffle = true,
    this.showLoop = true,
    this.showSeekBar = true,
    this.serviceOverride,
  });

  @override
  Widget build(BuildContext context) {
    final service = serviceOverride ?? EasyAudioPlayer.service;
    final resolvedTheme = AudioPlayerTheme.of(context, override: theme);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSeekBar)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: EasySeekBar(theme: resolvedTheme, service: service),
          ),
        ControlButtons(
          service: service,
          theme: resolvedTheme,
          showVolume: showVolume,
          showSpeed: showSpeed,
          showShuffle: showShuffle,
          showLoop: showLoop,
        ),
      ],
    );
  }
}
