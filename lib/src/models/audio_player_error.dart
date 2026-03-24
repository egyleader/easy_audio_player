enum AudioErrorCategory { network, decode, notFound, permission, unknown }

class AudioPlayerError {
  final String trackId;
  final String message;
  final AudioErrorCategory category;
  final Object? originalError;

  const AudioPlayerError({
    required this.trackId,
    required this.message,
    required this.category,
    this.originalError,
  });
}
