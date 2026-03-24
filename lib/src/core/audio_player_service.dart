// lib/src/core/audio_player_service.dart
import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../models/audio_player_error.dart';
import '../models/audio_track.dart';
import '../models/easy_loop_mode.dart';
import 'audio_player_state.dart';
import 'audio_player_service_interface.dart';
import 'track_source_mapper.dart';

class AudioPlayerService implements AudioPlayerServiceInterface {
  AudioPlayerService._();

  static AudioPlayerService? _instance;
  static AudioPlayerService get instance {
    assert(_instance != null,
        'AudioPlayerService is not initialized. Call EasyAudioPlayer.init() first.');
    return _instance!;
  }

  static Future<AudioPlayerService> create() async {
    assert(_instance == null, 'AudioPlayerService already initialized.');
    final service = AudioPlayerService._();
    await service._initialize();
    _instance = service;
    return service;
  }

  // ── Internal state ─────────────────────────────────────────────────────────
  late final AudioPlayer _player;
  final List<AudioTrack> _queue = [];
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  // ── BehaviorSubjects (internal, permanent subscriptions) ──────────────────
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

  // ── AudioPlayerServiceInterface: Streams ──────────────────────────────────
  @override
  Stream<EasyPlayerState> get playerStateStream => _playerStateSubject.stream;
  @override
  Stream<Duration> get positionStream => _positionSubject.stream;
  @override
  Stream<Duration?> get durationStream => _durationSubject.stream;
  @override
  Stream<Duration> get bufferedStream => _bufferedSubject.stream;
  @override
  Stream<AudioTrack?> get currentTrackStream => _currentTrackSubject.stream;
  @override
  Stream<List<AudioTrack>> get queueStream => _queueSubject.stream;
  @override
  Stream<EasyLoopMode> get loopModeStream => _loopModeSubject.stream;
  @override
  Stream<bool> get shuffleStream => _shuffleSubject.stream;
  @override
  Stream<double> get volumeStream => _volumeSubject.stream;
  @override
  Stream<double> get speedStream => _speedSubject.stream;
  @override
  Stream<AudioPlayerError> get errorStream => _errorSubject.stream;

  // ── AudioPlayerServiceInterface: Sync getters ─────────────────────────────
  @override
  EasyPlayerState get playerState => _playerStateSubject.value;
  @override
  Duration get position => _positionSubject.value;
  @override
  Duration? get duration => _durationSubject.value;
  @override
  AudioTrack? get currentTrack => _currentTrackSubject.value;
  @override
  List<AudioTrack> get queue => List.unmodifiable(_queueSubject.value);
  @override
  EasyLoopMode get loopMode => _loopModeSubject.value;
  @override
  bool get shuffle => _shuffleSubject.value;
  @override
  double get volume => _volumeSubject.value;
  @override
  double get speed => _speedSubject.value;

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> _initialize() async {
    _player = AudioPlayer();

    // Configure audio session for music playback
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Subscribe to just_audio streams permanently
    _subscriptions.addAll([
      _player.playerStateStream.listen(_onPlayerState),
      _player.positionStream.listen(_positionSubject.add),
      _player.durationStream.listen(_durationSubject.add),
      _player.bufferedPositionStream.listen(_bufferedSubject.add),
      _player.volumeStream.listen(_volumeSubject.add),
      _player.speedStream.listen(_speedSubject.add),
      _player.loopModeStream.listen((mode) => _loopModeSubject.add(_mapLoopMode(mode))),
      _player.shuffleModeEnabledStream.listen(_shuffleSubject.add),
      _player.currentIndexStream.listen(_onCurrentIndex),
      _player.playbackEventStream
          .where((event) => event.processingState == ProcessingState.idle)
          .listen((_) {}, onError: _onError),
    ]);
  }

  // ── Stream callbacks ───────────────────────────────────────────────────────
  void _onPlayerState(PlayerState state) {
    final pos = _positionSubject.value;
    final mapped = switch (state.processingState) {
      ProcessingState.idle => const PlayerIdle(),
      ProcessingState.loading || ProcessingState.buffering => const PlayerBuffering(),
      ProcessingState.ready => state.playing ? PlayerPlaying(pos) : PlayerPaused(pos),
      ProcessingState.completed => const PlayerCompleted(),
    };
    _playerStateSubject.add(mapped);
  }

  void _onCurrentIndex(int? index) {
    if (index != null && index < _queue.length) {
      _currentTrackSubject.add(_queue[index]);
    }
  }

  void _onError(Object error, [StackTrace? stackTrace]) {
    final current = _currentTrackSubject.value;
    _errorSubject.add(AudioPlayerError(
      trackId: current?.id ?? 'unknown',
      message: error.toString(),
      category: _categorizeError(error),
      originalError: error,
    ));
    // Auto-skip to next track on error
    skipToNext();
  }

  EasyLoopMode _mapLoopMode(LoopMode mode) => switch (mode) {
        LoopMode.off => EasyLoopMode.off,
        LoopMode.one => EasyLoopMode.one,
        LoopMode.all => EasyLoopMode.all,
      };

  AudioErrorCategory _categorizeError(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('network') || msg.contains('connection') || msg.contains('timeout')) {
      return AudioErrorCategory.network;
    }
    if (msg.contains('404') || msg.contains('not found')) {
      return AudioErrorCategory.notFound;
    }
    if (msg.contains('decode') || msg.contains('format')) {
      return AudioErrorCategory.decode;
    }
    if (msg.contains('permission')) return AudioErrorCategory.permission;
    return AudioErrorCategory.unknown;
  }

  // ── Queue Management ───────────────────────────────────────────────────────
  @override
  Future<void> load(List<AudioTrack> tracks, {int initialIndex = 0}) async {
    _queue
      ..clear()
      ..addAll(tracks);
    _queueSubject.add(List.unmodifiable(_queue));
    // TODO: Migrate to just_audio 0.10.x new playlist API when
    // just_audio_background compatibility is confirmed. Currently using
    // ConcatenatingAudioSource (deprecated in 0.10.0 but still functional).
    final source = ConcatenatingAudioSource(
      children: TrackSourceMapper.toAudioSources(tracks),
    );
    await _player.setAudioSource(source, initialIndex: initialIndex);
  }

  @override
  Future<void> add(AudioTrack track) async {
    _queue.add(track);
    _queueSubject.add(List.unmodifiable(_queue));
    final concat = _player.audioSource as ConcatenatingAudioSource?;
    await concat?.add(TrackSourceMapper.toAudioSource(track));
  }

  @override
  Future<void> insert(int index, AudioTrack track) async {
    _queue.insert(index, track);
    _queueSubject.add(List.unmodifiable(_queue));
    final concat = _player.audioSource as ConcatenatingAudioSource?;
    await concat?.insert(index, TrackSourceMapper.toAudioSource(track));
  }

  @override
  Future<void> remove(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    _queueSubject.add(List.unmodifiable(_queue));
    final concat = _player.audioSource as ConcatenatingAudioSource?;
    await concat?.removeAt(index);
  }

  @override
  Future<void> move(int from, int to) async {
    if (from < 0 || from >= _queue.length) return;
    final track = _queue.removeAt(from);
    _queue.insert(to, track);
    _queueSubject.add(List.unmodifiable(_queue));
    final concat = _player.audioSource as ConcatenatingAudioSource?;
    await concat?.move(from, to);
  }

  @override
  Future<void> clear() async {
    _queue.clear();
    _queueSubject.add([]);
    await _player.stop();
    final concat = _player.audioSource as ConcatenatingAudioSource?;
    if (concat != null) {
      await concat.clear();
    }
  }

  @override
  Future<void> skipToIndex(int index) => _player.seek(Duration.zero, index: index);

  // ── Playback Controls ──────────────────────────────────────────────────────
  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> skipToNext() => _player.seekToNext();
  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();
  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume.clamp(0.0, 1.0));
  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed.clamp(0.5, 2.0));

  @override
  Future<void> setLoopMode(EasyLoopMode mode) => _player.setLoopMode(switch (mode) {
        EasyLoopMode.off => LoopMode.off,
        EasyLoopMode.one => LoopMode.one,
        EasyLoopMode.all => LoopMode.all,
      });

  @override
  Future<void> setShuffle(bool enabled) => _player.setShuffleModeEnabled(enabled);

  // ── Dispose ────────────────────────────────────────────────────────────────
  Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();

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

    await _player.dispose();
    _instance = null;
  }
}
