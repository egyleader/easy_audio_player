// lib/src/models/audio_player_theme.dart
import 'package:flutter/material.dart';

class AudioPlayerTheme {
  final Color? primaryColor;
  final Color? backgroundColor;
  final Color? progressBarColor;
  final Color? bufferedBarColor;
  final Color? waveformColor;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final IconThemeData? iconTheme;
  final double? borderRadius;
  final double? miniArtworkSize;
  final double? expandedArtworkSize;

  const AudioPlayerTheme({
    this.primaryColor,
    this.backgroundColor,
    this.progressBarColor,
    this.bufferedBarColor,
    this.waveformColor,
    this.titleStyle,
    this.subtitleStyle,
    this.iconTheme,
    this.borderRadius,
    this.miniArtworkSize,
    this.expandedArtworkSize,
  });

  /// Resolves this theme against the ambient Material 3 theme.
  AudioPlayerTheme resolve(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return AudioPlayerTheme(
      primaryColor: primaryColor ?? cs.primary,
      backgroundColor: backgroundColor ?? cs.surface,
      progressBarColor: progressBarColor ?? cs.primary,
      bufferedBarColor: bufferedBarColor ?? cs.surfaceContainerHighest,
      waveformColor: waveformColor ?? cs.primary.withValues(alpha: 0.6),
      titleStyle: titleStyle ?? tt.titleMedium,
      subtitleStyle: subtitleStyle ?? tt.bodyMedium,
      iconTheme: iconTheme ?? IconTheme.of(context),
      borderRadius: borderRadius ?? 12.0,
      miniArtworkSize: miniArtworkSize ?? 48.0,
      expandedArtworkSize: expandedArtworkSize ?? 240.0,
    );
  }

  /// Convenience: resolve from context and return a fully populated theme.
  static AudioPlayerTheme of(BuildContext context, {AudioPlayerTheme? override}) {
    return (override ?? const AudioPlayerTheme()).resolve(context);
  }
}
