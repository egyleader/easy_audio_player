import 'package:flutter/material.dart';
import 'package:flutter_audioplayer/helpers/init_just_audio_background.dart';
import 'package:flutter_audioplayer/models/notification_configuration.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_audioplayer/widgets/players/full_audio_player.dart';

void main() async {
  // init the background service to display notifications while playing
  await initJustAudioBackground(NotificationSettings(androidNotificationChannelId: 'com.example.example'));
  runApp(MaterialApp(
    home: HomeScreen(),
  ));
}

class HomeScreen extends StatelessWidget {
  HomeScreen({Key? key}) : super(key: key);
  static const routeName = '/';

  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: [
    AudioSource.uri(Uri.parse('https://file-examples-com.github.io/uploads/2017/11/file_example_MP3_700KB.mp3'),
        tag: MediaItem(
            id: '1',
            artUri: Uri.parse('https://picsum.photos/id/237/200/300'),
            title: 'Audio Title ',
            album: 'amazing album'))
  ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: FullAudioPlayer(autoPlay: false, playlist: _playlist),
                ))));
  }
}
