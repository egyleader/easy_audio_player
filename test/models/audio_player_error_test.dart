import 'package:flutter_test/flutter_test.dart';
import 'package:easy_audio_player/easy_audio_player.dart';

void main() {
  group('AudioPlayerError', () {
    test('stores all fields', () {
      final error = AudioPlayerError(
        trackId: 'track_1',
        message: 'File not found',
        category: AudioErrorCategory.notFound,
        originalError: Exception('404'),
      );

      expect(error.trackId, 'track_1');
      expect(error.message, 'File not found');
      expect(error.category, AudioErrorCategory.notFound);
      expect(error.originalError, isA<Exception>());
    });

    test('originalError is optional', () {
      final error = AudioPlayerError(
        trackId: 'x',
        message: 'Network error',
        category: AudioErrorCategory.network,
      );
      expect(error.originalError, isNull);
    });
  });

  group('EasyLoopMode', () {
    test('has three values', () {
      expect(EasyLoopMode.values.length, 3);
      expect(EasyLoopMode.values, containsAll([EasyLoopMode.off, EasyLoopMode.one, EasyLoopMode.all]));
    });
  });
}
