import 'package:flutter_audioplayer/models/audio.dart';
import 'package:audio_service/audio_service.dart';

class Playlist {
  const Playlist({
    required this.audios,
    this.ratingStyle = RatingStyle.none,
  });

  final List<Audio> audios;

  /// The style of a [Rating].
  final RatingStyle ratingStyle;
}
