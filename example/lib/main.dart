import 'package:easy_audio_player/easy_audio_player.dart';
import 'package:flutter/material.dart';

void main() async {
  // Initialize EasyAudioPlayer with notification configuration
  await EasyAudioPlayer.init(
    config: AudioPlayerConfig(
      androidNotificationChannelId: 'com.example.example',
      androidNotificationChannelName: 'Music',
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Audio Player',
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    final service = EasyAudioPlayer.service;
    final track = AudioTrack.network(
      url: 'https://file-examples-com.github.io/uploads/2017/11/file_example_MP3_700KB.mp3',
      id: '1',
      title: 'Audio Title',
      album: 'Amazing Album',
      artworkUrl: 'https://picsum.photos/300/300',
    );
    await service.load([track]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Easy Audio Player')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: ExpandedPlayer(
              showPlaylist: true,
              showWaveform: true,
            ),
          ),
        ),
      ),
    );
  }
}
