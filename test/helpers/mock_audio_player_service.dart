// test/helpers/mock_audio_player_service.dart
import 'package:easy_audio_player/src/core/audio_player_service_interface.dart';
import 'package:easy_audio_player/easy_audio_player.dart';
import 'package:rxdart/rxdart.dart';

/// A controllable stub of AudioPlayerService for widget tests.
/// Does not require just_audio platform channels.
class MockAudioPlayerService implements AudioPlayerServiceInterface {
  final _playerStateSubject = BehaviorSubject<EasyPlayerState>.seeded(const PlayerIdle());
  final _positionSubject = BehaviorSubject<Duration>.seeded(Duration.zero);
  final _durationSubject = BehaviorSubject<Duration?>.seeded(null);
  final _bufferedSubject = BehaviorSubject<Duration>.seeded(Duration.zero);
  final _currentTrackSubject = BehaviorSubject<AudioTrack?>.seeded(null);
  final _queueSubject = BehaviorSubject<List<AudioTrack>>.seeded([]);
  final _loopModeSubject = BehaviorSubject<EasyLoopMode>.seeded(EasyLoopMode.off);
  final _shuffleSubject = BehaviorSubject<bool>.seeded(false);
  final _volumeSubject = BehaviorSubject<double>.seeded(1.0);
  final _speedSubject = BehaviorSubject<double>.seeded(1.0);
  final _errorSubject = PublishSubject<AudioPlayerError>();

  // Streams
  @override Stream<EasyPlayerState> get playerStateStream => _playerStateSubject.stream;
  @override Stream<Duration> get positionStream => _positionSubject.stream;
  @override Stream<Duration?> get durationStream => _durationSubject.stream;
  @override Stream<Duration> get bufferedStream => _bufferedSubject.stream;
  @override Stream<AudioTrack?> get currentTrackStream => _currentTrackSubject.stream;
  @override Stream<List<AudioTrack>> get queueStream => _queueSubject.stream;
  @override Stream<EasyLoopMode> get loopModeStream => _loopModeSubject.stream;
  @override Stream<bool> get shuffleStream => _shuffleSubject.stream;
  @override Stream<double> get volumeStream => _volumeSubject.stream;
  @override Stream<double> get speedStream => _speedSubject.stream;
  @override Stream<AudioPlayerError> get errorStream => _errorSubject.stream;

  // Sync getters
  @override EasyPlayerState get playerState => _playerStateSubject.value;
  @override Duration get position => _positionSubject.value;
  @override Duration? get duration => _durationSubject.value;
  @override AudioTrack? get currentTrack => _currentTrackSubject.value;
  @override List<AudioTrack> get queue => List.unmodifiable(_queueSubject.value);
  @override EasyLoopMode get loopMode => _loopModeSubject.value;
  @override bool get shuffle => _shuffleSubject.value;
  @override double get volume => _volumeSubject.value;
  @override double get speed => _speedSubject.value;

  // Stub controls (no-op, return immediately)
  @override Future<void> load(List<AudioTrack> tracks, {int initialIndex = 0}) async {
    _queueSubject.add(List.unmodifiable(tracks));
    if (tracks.isNotEmpty && initialIndex < tracks.length) {
      _currentTrackSubject.add(tracks[initialIndex]);
    }
  }
  @override Future<void> add(AudioTrack track) async { _queueSubject.add([..._queueSubject.value, track]); }
  @override Future<void> insert(int index, AudioTrack track) async {
    final q = [..._queueSubject.value]..insert(index, track);
    _queueSubject.add(q);
  }
  @override Future<void> remove(int index) async {
    final q = [..._queueSubject.value]..removeAt(index);
    _queueSubject.add(q);
  }
  @override Future<void> move(int from, int to) async {
    final q = [..._queueSubject.value];
    final track = q.removeAt(from);
    q.insert(to, track);
    _queueSubject.add(q);
  }
  @override Future<void> clear() async { _queueSubject.add([]); _currentTrackSubject.add(null); }
  @override Future<void> skipToIndex(int index) async {
    final q = _queueSubject.value;
    if (index >= 0 && index < q.length) _currentTrackSubject.add(q[index]);
  }
  @override Future<void> play() async => _playerStateSubject.add(PlayerPlaying(_positionSubject.value));
  @override Future<void> pause() async => _playerStateSubject.add(PlayerPaused(_positionSubject.value));
  @override Future<void> stop() async => _playerStateSubject.add(const PlayerIdle());
  @override Future<void> seek(Duration position) async => _positionSubject.add(position);
  @override Future<void> skipToNext() async {}
  @override Future<void> skipToPrevious() async {}
  @override Future<void> setVolume(double volume) async => _volumeSubject.add(volume);
  @override Future<void> setSpeed(double speed) async => _speedSubject.add(speed);
  @override Future<void> setLoopMode(EasyLoopMode mode) async => _loopModeSubject.add(mode);
  @override Future<void> setShuffle(bool enabled) async => _shuffleSubject.add(enabled);

  // Test helpers — call these in tests to simulate state changes
  void emitState(EasyPlayerState state) => _playerStateSubject.add(state);
  void emitPosition(Duration pos) => _positionSubject.add(pos);
  void emitDuration(Duration? dur) => _durationSubject.add(dur);
  void emitCurrentTrack(AudioTrack? track) => _currentTrackSubject.add(track);
  void emitError(AudioPlayerError error) => _errorSubject.add(error);

  Future<void> dispose() async {
    await _playerStateSubject.close();
    await _positionSubject.close();
    await _durationSubject.close();
    await _bufferedSubject.close();
    await _currentTrackSubject.close();
    await _queueSubject.close();
    await _loopModeSubject.close();
    await _shuffleSubject.close();
    await _volumeSubject.close();
    await _speedSubject.close();
    await _errorSubject.close();
  }
}
