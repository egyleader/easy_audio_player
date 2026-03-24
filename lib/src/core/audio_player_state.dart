// lib/src/core/audio_player_state.dart
import '../models/audio_player_error.dart';

sealed class EasyPlayerState {
  const EasyPlayerState();
}

class PlayerIdle extends EasyPlayerState {
  const PlayerIdle();
}

class PlayerBuffering extends EasyPlayerState {
  const PlayerBuffering();
}

class PlayerPlaying extends EasyPlayerState {
  final Duration position;
  const PlayerPlaying(this.position);
}

class PlayerPaused extends EasyPlayerState {
  final Duration position;
  const PlayerPaused(this.position);
}

class PlayerCompleted extends EasyPlayerState {
  const PlayerCompleted();
}

class PlayerError extends EasyPlayerState {
  final AudioPlayerError error;
  const PlayerError(this.error);
}
