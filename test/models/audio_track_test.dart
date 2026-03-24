// test/models/audio_track_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_audio_player/easy_audio_player.dart';

void main() {
  group('AudioTrack.network', () {
    test('sets all fields correctly', () {
      final track = AudioTrack.network(
        id: '1',
        url: 'https://example.com/track.mp3',
        title: 'Test Track',
        artist: 'Artist',
        album: 'Album',
        artworkUrl: 'https://example.com/art.jpg',
        duration: const Duration(seconds: 180),
        extras: {'key': 'value'},
      );

      expect(track.id, '1');
      expect(track.title, 'Test Track');
      expect(track.artist, 'Artist');
      expect(track.album, 'Album');
      expect(track.artworkUrl, 'https://example.com/art.jpg');
      expect(track.duration, const Duration(seconds: 180));
      expect(track.extras, {'key': 'value'});
    });

    test('optional fields default to null', () {
      final track = AudioTrack.network(id: '1', url: 'https://x.com/t.mp3', title: 'T');
      expect(track.artist, isNull);
      expect(track.album, isNull);
      expect(track.artworkUrl, isNull);
      expect(track.duration, isNull);
      expect(track.extras, isNull);
    });
  });

  group('AudioTrack.file', () {
    test('sets file and required fields', () {
      final file = File('/path/to/track.mp3');
      final track = AudioTrack.file(id: '2', file: file, title: 'Local Track');
      expect(track.id, '2');
      expect(track.title, 'Local Track');
    });
  });

  group('AudioTrack.asset', () {
    test('sets assetPath and required fields', () {
      final track = AudioTrack.asset(
        id: '3',
        assetPath: 'assets/audio/intro.mp3',
        title: 'Intro',
      );
      expect(track.id, '3');
      expect(track.title, 'Intro');
    });
  });
}
