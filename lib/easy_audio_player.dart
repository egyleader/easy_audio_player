/// Easy Audio Player — drop-in Flutter audio player with background
/// playback, notification controls, and Material 3 adaptive theming.
///
/// Usage:
/// ```dart
/// void main() async {
///   await EasyAudioPlayer.init(
///     config: AudioPlayerConfig(
///       androidNotificationChannelId: 'com.myapp.audio',
///       androidNotificationChannelName: 'Music',
///     ),
///   );
///   runApp(MyApp());
/// }
/// ```
library;

// Core lifecycle
export 'src/core/easy_audio_player.dart';
// AudioPlayerService is NOT exported — access it only via EasyAudioPlayer.service
// which returns AudioPlayerServiceInterface. This keeps the public API surface minimal.
export 'src/core/audio_player_service_interface.dart';
export 'src/core/audio_player_state.dart';
export 'src/core/audio_player_config.dart';

// Models
export 'src/models/audio_track.dart';
export 'src/models/audio_player_error.dart';
export 'src/models/easy_loop_mode.dart';
export 'src/models/audio_player_theme.dart';

// Widgets
export 'src/widgets/mini_player.dart';
export 'src/widgets/expanded_player.dart';
export 'src/widgets/player_controls.dart';

// Waveform support (Android, iOS, macOS only)
export 'src/widgets/components/waveform_widget.dart' show WaveformWidget, isWaveformSupported;
