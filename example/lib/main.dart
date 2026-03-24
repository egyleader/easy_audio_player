// example/lib/main.dart
import 'package:easy_audio_player/easy_audio_player.dart';
import 'package:flutter/material.dart';

import 'screens/expanded_player_screen.dart';
import 'screens/features_screen.dart';
import 'screens/mini_player_screen.dart';
import 'screens/player_controls_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyAudioPlayer.init(
    config: const AudioPlayerConfig(
      androidNotificationChannelId: 'com.example.easy_audio_player',
      androidNotificationChannelName: 'Easy Audio Player',
    ),
  );

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'easy_audio_player Demo',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final _screens = const [
    MiniPlayerScreen(),
    ExpandedPlayerScreen(),
    PlayerControlsScreen(),
    FeaturesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Mini',
          ),
          NavigationDestination(
            icon: Icon(Icons.music_note),
            label: 'Expanded',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune),
            label: 'Controls',
          ),
          NavigationDestination(
            icon: Icon(Icons.science_outlined),
            label: 'Features',
          ),
        ],
      ),
    );
  }
}
