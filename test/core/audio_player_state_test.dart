// test/core/audio_player_state_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_audio_player/easy_audio_player.dart';

void main() {
  group('EasyPlayerState sealed class', () {
    test('PlayerPlaying holds position', () {
      const state = PlayerPlaying(Duration(seconds: 30));
      expect(state.position, const Duration(seconds: 30));
    });

    test('PlayerPaused holds position', () {
      const state = PlayerPaused(Duration(seconds: 15));
      expect(state.position, const Duration(seconds: 15));
    });

    test('PlayerError holds AudioPlayerError', () {
      const error = AudioPlayerError(
        trackId: 'x',
        message: 'fail',
        category: AudioErrorCategory.unknown,
      );
      const state = PlayerError(error);
      expect(state.error.trackId, 'x');
    });

    test('exhaustive switch compiles for all subtypes', () {
      EasyPlayerState state = const PlayerIdle();
      final label = switch (state) {
        PlayerIdle() => 'idle',
        PlayerBuffering() => 'buffering',
        PlayerPlaying() => 'playing',
        PlayerPaused() => 'paused',
        PlayerCompleted() => 'completed',
        PlayerError() => 'error',
      };
      expect(label, 'idle');
    });
  });
}
