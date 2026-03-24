// lib/src/widgets/components/control_buttons.dart
import 'package:flutter/material.dart';

import '../../core/audio_player_service_interface.dart';
import '../../models/audio_player_theme.dart';
import '../../models/easy_loop_mode.dart';
import '../../core/audio_player_state.dart'; // sealed EasyPlayerState

class ControlButtons extends StatelessWidget {
  final AudioPlayerServiceInterface service;
  final AudioPlayerTheme theme;
  final bool showVolume;
  final bool showSpeed;
  final bool showShuffle;
  final bool showLoop;

  const ControlButtons({
    super.key,
    required this.service,
    required this.theme,
    this.showVolume = false,
    this.showSpeed = false,
    this.showShuffle = false,
    this.showLoop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showShuffle) _ShuffleButton(service: service, theme: theme),
            IconButton(
              icon: const Icon(Icons.skip_previous),
              onPressed: service.skipToPrevious,
              color: theme.primaryColor,
              iconSize: 32,
            ),
            _PlayPauseButton(service: service, theme: theme),
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: service.skipToNext,
              color: theme.primaryColor,
              iconSize: 32,
            ),
            if (showLoop) _LoopButton(service: service, theme: theme),
          ],
        ),
        if (showVolume) _VolumeRow(service: service, theme: theme),
        if (showSpeed) _SpeedRow(service: service, theme: theme),
      ],
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final AudioPlayerServiceInterface service;
  final AudioPlayerTheme theme;
  const _PlayPauseButton({required this.service, required this.theme});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EasyPlayerState>(
      stream: service.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const PlayerIdle();
        return switch (state) {
          PlayerBuffering() => SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.primaryColor,
              ),
            ),
          PlayerPlaying() => IconButton(
              icon: const Icon(Icons.pause_circle_filled),
              onPressed: service.pause,
              color: theme.primaryColor,
              iconSize: 56,
            ),
          PlayerCompleted() => IconButton(
              icon: const Icon(Icons.replay),
              onPressed: () => service.seek(Duration.zero),
              color: theme.primaryColor,
              iconSize: 56,
            ),
          _ => IconButton(
              icon: const Icon(Icons.play_circle_filled),
              onPressed: service.play,
              color: theme.primaryColor,
              iconSize: 56,
            ),
        };
      },
    );
  }
}

class _LoopButton extends StatelessWidget {
  final AudioPlayerServiceInterface service;
  final AudioPlayerTheme theme;
  const _LoopButton({required this.service, required this.theme});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EasyLoopMode>(
      stream: service.loopModeStream,
      builder: (context, snapshot) {
        final mode = snapshot.data ?? EasyLoopMode.off;
        return IconButton(
          icon: Icon(
            mode == EasyLoopMode.one ? Icons.repeat_one : Icons.repeat,
          ),
          color: mode == EasyLoopMode.off
              ? theme.primaryColor?.withValues(alpha: 0.4)
              : theme.primaryColor,
          onPressed: () {
            final next = switch (mode) {
              EasyLoopMode.off => EasyLoopMode.all,
              EasyLoopMode.all => EasyLoopMode.one,
              EasyLoopMode.one => EasyLoopMode.off,
            };
            service.setLoopMode(next);
          },
        );
      },
    );
  }
}

class _ShuffleButton extends StatelessWidget {
  final AudioPlayerServiceInterface service;
  final AudioPlayerTheme theme;
  const _ShuffleButton({required this.service, required this.theme});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: service.shuffleStream,
      builder: (context, snapshot) {
        final enabled = snapshot.data ?? false;
        return IconButton(
          icon: const Icon(Icons.shuffle),
          color: enabled
              ? theme.primaryColor
              : theme.primaryColor?.withValues(alpha: 0.4),
          onPressed: () => service.setShuffle(!enabled),
        );
      },
    );
  }
}

class _VolumeRow extends StatelessWidget {
  final AudioPlayerServiceInterface service;
  final AudioPlayerTheme theme;
  const _VolumeRow({required this.service, required this.theme});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: service.volumeStream,
      builder: (context, snapshot) {
        final volume = snapshot.data ?? 1.0;
        return Row(
          children: [
            Icon(Icons.volume_down, color: theme.subtitleStyle?.color, size: 18),
            Expanded(
              child: Slider(
                value: volume,
                onChanged: service.setVolume,
                activeColor: theme.primaryColor,
              ),
            ),
            Icon(Icons.volume_up, color: theme.subtitleStyle?.color, size: 18),
          ],
        );
      },
    );
  }
}

class _SpeedRow extends StatelessWidget {
  final AudioPlayerServiceInterface service;
  final AudioPlayerTheme theme;
  const _SpeedRow({required this.service, required this.theme});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: service.speedStream,
      builder: (context, snapshot) {
        final speed = snapshot.data ?? 1.0;
        return Row(
          children: [
            Text('${speed.toStringAsFixed(1)}x',
                style: theme.subtitleStyle?.copyWith(fontSize: 12)),
            Expanded(
              child: Slider(
                value: speed,
                min: 0.5,
                max: 2.0,
                divisions: 6,
                onChanged: service.setSpeed,
                activeColor: theme.primaryColor,
              ),
            ),
          ],
        );
      },
    );
  }
}
