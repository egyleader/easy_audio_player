// lib/src/models/audio_track.dart
import 'dart:io';

// Not private (_) so it can be accessed by TrackSourceMapper and WaveformWidget
// in other files within src/. Not exported from easy_audio_player.dart.
enum TrackSourceType { network, file }

class AudioTrack {
  final String id;
  final String title;
  final String? artist;
  final String? album;
  final String? artworkUrl;
  final Duration? duration;
  final Map<String, dynamic>? extras;

  final TrackSourceType _sourceType;
  final String? _url;
  final File? _file;

  AudioTrack.network({
    required this.id,
    required String url,
    required this.title,
    this.artist,
    this.album,
    this.artworkUrl,
    this.duration,
    this.extras,
  })  : _sourceType = TrackSourceType.network,
        _url = url,
        _file = null;

  AudioTrack.file({
    required this.id,
    required File file,
    required this.title,
    this.artist,
    this.album,
    this.artworkUrl,
    this.duration,
    this.extras,
  })  : _sourceType = TrackSourceType.file,
        _url = null,
        _file = file;

  // Internal accessors for TrackSourceMapper and WaveformWidget
  TrackSourceType get sourceType => _sourceType;
  String? get url => _url;
  File? get file => _file;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AudioTrack && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
