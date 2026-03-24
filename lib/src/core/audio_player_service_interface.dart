import '../models/audio_player_error.dart';
import '../models/audio_track.dart';
import '../models/easy_loop_mode.dart';
import 'audio_player_state.dart';

/// Abstract interface implemented by both [AudioPlayerService] and
/// [MockAudioPlayerService]. Widgets accept this type for testability.
abstract interface class AudioPlayerServiceInterface {
  Stream<EasyPlayerState> get playerStateStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<Duration> get bufferedStream;
  Stream<AudioTrack?> get currentTrackStream;
  Stream<List<AudioTrack>> get queueStream;
  Stream<EasyLoopMode> get loopModeStream;
  Stream<bool> get shuffleStream;
  Stream<double> get volumeStream;
  Stream<double> get speedStream;
  Stream<AudioPlayerError> get errorStream;

  // Sync getters for current values
  EasyPlayerState get playerState;
  Duration get position;
  Duration? get duration;
  AudioTrack? get currentTrack;
  List<AudioTrack> get queue;
  EasyLoopMode get loopMode;
  bool get shuffle;
  double get volume;
  double get speed;

  // Queue management
  Future<void> load(List<AudioTrack> tracks, {int initialIndex = 0});
  Future<void> add(AudioTrack track);
  Future<void> insert(int index, AudioTrack track);
  Future<void> remove(int index);
  Future<void> move(int from, int to);
  Future<void> clear();
  Future<void> skipToIndex(int index);

  // Playback control
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> skipToNext();
  Future<void> skipToPrevious();
  Future<void> setVolume(double volume);
  Future<void> setSpeed(double speed);
  Future<void> setLoopMode(EasyLoopMode mode);
  Future<void> setShuffle(bool enabled);
}
