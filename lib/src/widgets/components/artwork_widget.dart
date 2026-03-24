// lib/src/widgets/components/artwork_widget.dart
import 'package:flutter/material.dart';

import '../../models/audio_player_theme.dart';

class ArtworkWidget extends StatelessWidget {
  final String? artworkUrl;
  final double size;
  final AudioPlayerTheme theme;

  const ArtworkWidget({
    super.key,
    required this.artworkUrl,
    required this.size,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(theme.borderRadius ?? 12),
      ),
      child: artworkUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(theme.borderRadius ?? 12),
              child: Image.network(
                artworkUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(context),
              ),
            )
          : _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) => Icon(
        Icons.music_note,
        size: size * 0.4,
        color: theme.primaryColor,
      );
}
