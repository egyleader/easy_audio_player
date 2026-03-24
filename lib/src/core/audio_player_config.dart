import 'dart:ui';

/// Configuration passed to [EasyAudioPlayer.init].
class AudioPlayerConfig {
  /// Android notification channel ID. Must be unique per app.
  final String androidNotificationChannelId;

  /// Android notification channel name shown in system settings.
  final String androidNotificationChannelName;

  /// Android notification icon resource name. Defaults to app icon.
  final String androidNotificationIcon;

  /// Optional tint color for the Android notification.
  final Color? notificationColor;

  const AudioPlayerConfig({
    required this.androidNotificationChannelId,
    required this.androidNotificationChannelName,
    this.androidNotificationIcon = 'mipmap/ic_launcher',
    this.notificationColor,
  });
}
