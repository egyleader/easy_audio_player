import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/audio_track.dart';

/// Internal: converts [AudioTrack] into a just_audio [AudioSource] with a
/// [MediaItem] tag for background notification display.
/// Not exported publicly.
class TrackSourceMapper {
  static AudioSource toAudioSource(AudioTrack track) {
    final tag = MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      album: track.album,
      artUri: track.artworkUrl != null ? Uri.parse(track.artworkUrl!) : null,
      duration: track.duration,
      extras: track.extras,
    );

    return switch (track.sourceType) {
      TrackSourceType.network => AudioSource.uri(
          Uri.parse(track.url!),
          tag: tag,
        ),
      TrackSourceType.file => AudioSource.uri(
          track.file!.uri,
          tag: tag,
        ),
      TrackSourceType.asset => AudioSource.asset(
          track.assetPath!,
          tag: tag,
        ),
    };
  }

  static List<AudioSource> toAudioSources(List<AudioTrack> tracks) =>
      tracks.map(toAudioSource).toList();
}
