import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
class Audio {
  Audio({
    required this.id,
    required this.audioSource,
    required this.title,
    this.album,
    this.artist,
    this.genre,
    this.duration,
    this.image,
    this.playable = true,
    this.displayTitle,
    this.displaySubtitle,
    this.displayDescription,
    this.rating,
    this.extras,
  });

  /// A unique id.
  final String id;


  /// The details of the audio file that as a [AudioSource] based class 
  /// witch gives you the options of :
  /// * [ClippingAudioSource] : clips the audio of a [UriAudioSource] between a  certain start and end time.
  /// * [LoopingAudioSource] : loops a nested [AudioSource] a finite number of times.
  /// * [ProgressiveAudioSource] :  regular media file such as an MP3 or M4A
  /// * [LockCachingAudioSource] :experimental audio source that caches the audio while it is being downloaded and played.
  /// * [AudioSource.uri()] : Creates an [AudioSource] from a [Uri] with optional headers.
  /// * [DashAudioSource] : An [AudioSource] representing a DASH stream.
  /// * [HlsAudioSource] : representing an HLS stream.
  /// 
  final AudioSource audioSource;

  /// The title of this media item.
  final String title;

  /// The album this media item belongs to.
  final String? album;

  /// The artist of this media item.
  final String? artist;

  /// The genre of this media item.
  final String? genre;

  /// The duration of this media item.
  final Duration? duration;

  /// The image for this media item as a uri.
  final Uri? image;

  /// Whether this is playable (i.e. not a folder).
  final bool? playable;

  /// Override the default title for display purposes.
  final String? displayTitle;

  /// Override the default subtitle for display purposes.
  final String? displaySubtitle;

  /// Override the default description for display purposes.
  final String? displayDescription;

  /// The rating of the media item.
  final Rating? rating;

  /// A map of additional metadata for the media item.
  ///
  /// The values must be of type `int`, `String`, `bool` or `double`.
  final Map<String, dynamic>? extras;

  Audio copyWith({
    String? id,
    AudioSource? audioSource,
    String? title,
    String? album,
    String? artist,
    String? genre,
    Duration? duration,
    Uri? image,
    bool? playable,
    String? displayTitle,
    String? displaySubtitle,
    String? displayDescription,
    Rating? rating,
    Map<String, dynamic>? extras,
  }) {
    return Audio(
      id: id ?? this.id,
      audioSource: audioSource ?? this.audioSource,
      title: title ?? this.title,
      album: album ?? this.album,
      artist: artist ?? this.artist,
      genre: genre ?? this.genre,
      duration: duration ?? this.duration,
      image: image ?? this.image,
      playable: playable ?? this.playable,
      displayTitle: displayTitle ?? this.displayTitle,
      displaySubtitle: displaySubtitle ?? this.displaySubtitle,
      displayDescription: displayDescription ?? this.displayDescription,
      rating: rating ?? this.rating,
      extras: extras ?? this.extras,
    );
  }
}
