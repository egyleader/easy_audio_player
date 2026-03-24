// test/models/audio_player_config_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_audio_player/easy_audio_player.dart';

void main() {
  group('AudioPlayerConfig', () {
    test('sets required fields correctly', () {
      const config = AudioPlayerConfig(
        androidNotificationChannelId: 'com.example.channel',
        androidNotificationChannelName: 'Music',
      );

      expect(config.androidNotificationChannelId, 'com.example.channel');
      expect(config.androidNotificationChannelName, 'Music');
    });

    test('androidNotificationIcon defaults to mipmap/ic_launcher', () {
      const config = AudioPlayerConfig(
        androidNotificationChannelId: 'com.example.channel',
        androidNotificationChannelName: 'Music',
      );

      expect(config.androidNotificationIcon, 'mipmap/ic_launcher');
    });

    test('notificationColor defaults to null', () {
      const config = AudioPlayerConfig(
        androidNotificationChannelId: 'com.example.channel',
        androidNotificationChannelName: 'Music',
      );

      expect(config.notificationColor, isNull);
    });

    test('accepts custom androidNotificationIcon', () {
      const config = AudioPlayerConfig(
        androidNotificationChannelId: 'com.example.channel',
        androidNotificationChannelName: 'Music',
        androidNotificationIcon: 'drawable/ic_music',
      );

      expect(config.androidNotificationIcon, 'drawable/ic_music');
    });

    test('accepts notificationColor', () {
      const config = AudioPlayerConfig(
        androidNotificationChannelId: 'com.example.channel',
        androidNotificationChannelName: 'Music',
        notificationColor: Colors.blue,
      );

      expect(config.notificationColor, Colors.blue);
    });
  });
}
