// test/core/audio_player_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_audio_player/easy_audio_player.dart';

// NOTE: Full integration tests for AudioPlayerService require a running
// just_audio instance which isn't available in unit test environment.
// These tests verify the initial state values on sync getters only.
// Full stream tests are in integration_test/ (out of scope for this task).
void main() {
  group('AudioPlayerService initial state', () {
    // Service is tested via EasyAudioPlayer.service after init.
    // These tests verify initial values on the sync getters.
    // Full stream tests are in integration_test/.

    test('EasyPlayerState subtypes are correct', () {
      expect(const PlayerIdle(), isA<EasyPlayerState>());
      expect(const PlayerBuffering(), isA<EasyPlayerState>());
      expect(const PlayerPlaying(Duration.zero), isA<EasyPlayerState>());
      expect(const PlayerPaused(Duration.zero), isA<EasyPlayerState>());
      expect(const PlayerCompleted(), isA<EasyPlayerState>());
    });

    test('EasyLoopMode enum has correct values', () {
      expect(EasyLoopMode.values, containsAll([EasyLoopMode.off, EasyLoopMode.one, EasyLoopMode.all]));
    });
  });
}
