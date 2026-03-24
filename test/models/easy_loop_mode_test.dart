// test/models/easy_loop_mode_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_audio_player/easy_audio_player.dart';

void main() {
  group('EasyLoopMode', () {
    test('has three values: off, one, all', () {
      expect(EasyLoopMode.values, hasLength(3));
      expect(EasyLoopMode.values, containsAll([
        EasyLoopMode.off,
        EasyLoopMode.one,
        EasyLoopMode.all,
      ]));
    });

    test('exhaustive switch compiles for all values', () {
      String label(EasyLoopMode mode) => switch (mode) {
        EasyLoopMode.off => 'off',
        EasyLoopMode.one => 'one',
        EasyLoopMode.all => 'all',
      };

      expect(label(EasyLoopMode.off), 'off');
      expect(label(EasyLoopMode.one), 'one');
      expect(label(EasyLoopMode.all), 'all');
    });
  });
}
