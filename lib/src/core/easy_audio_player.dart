// lib/src/core/easy_audio_player.dart
import 'package:just_audio_background/just_audio_background.dart';

import 'audio_player_config.dart';
import 'audio_player_service.dart';
import 'audio_player_service_interface.dart';

/// Entry point for the easy_audio_player package.
///
/// Call [init] once in `main()` before `runApp()`:
/// ```dart
/// void main() async {
///   await EasyAudioPlayer.init(config: AudioPlayerConfig(...));
///   runApp(MyApp());
/// }
/// ```
class EasyAudioPlayer {
  EasyAudioPlayer._();

  /// Initializes background playback and the audio player service.
  /// Must be called before [runApp] on Android.
  static Future<void> init({required AudioPlayerConfig config}) async {
    await JustAudioBackground.init(
      androidNotificationChannelId: config.androidNotificationChannelId,
      androidNotificationChannelName: config.androidNotificationChannelName,
      androidNotificationIcon: config.androidNotificationIcon,
      notificationColor: config.notificationColor,
      androidNotificationOngoing: false,
      preloadArtwork: true,
    );
    await AudioPlayerService.create();
  }

  /// The singleton audio player service. Access streams and controls here.
  /// Returns [AudioPlayerServiceInterface] — the concrete [AudioPlayerService]
  /// is intentionally not exported to keep the public API surface minimal.
  static AudioPlayerServiceInterface get service => AudioPlayerService.instance;

  /// Disposes the audio player service and stops background playback.
  /// The singleton resets — [init] can be called again if needed.
  static Future<void> dispose() => AudioPlayerService.instance.dispose();
}
