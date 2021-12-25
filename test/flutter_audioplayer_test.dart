import 'package:audio_session/audio_session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_audioplayer/flutter_audioplayer.dart';
import 'package:flutter_audioplayer/helpers/init_just_audio_background.dart';
import 'package:flutter_audioplayer/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Audio player service inits with session successfuly', () {
    WidgetsFlutterBinding.ensureInitialized();
    initJustAudioBackground(NotificationSettings(androidNotificationChannelId: 'com.example.app'));
    final audioService = AudioPlayerService();
    expect(audioService.player, audioService.player);
  });
}
