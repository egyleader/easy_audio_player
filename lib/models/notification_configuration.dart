import 'package:flutter/painting.dart';

class NotificationSettings {
  final bool androidResumeOnClick;
  final String? androidNotificationChannelId;
  final String androidNotificationChannelName;
  final String? androidNotificationChannelDescription;
  final Color? notificationColor;
  final String androidNotificationIcon;
  final bool androidShowNotificationBadge;
  final bool androidNotificationClickStartsActivity;
  final bool androidNotificationOngoing;
  final bool androidStopForegroundOnPause;
  final int? artDownscaleWidth;
  final int? artDownscaleHeight;
  final Duration fastForwardInterval;
  final Duration rewindInterval;
  final bool preloadArtwork;
  final Map<String, dynamic>? androidBrowsableRootExtras;

  NotificationSettings({
    this.androidResumeOnClick = true,
    required this.androidNotificationChannelId,
    this.androidNotificationChannelName = 'Notifications',
    this.androidNotificationChannelDescription,
    this.notificationColor,
    this.androidNotificationIcon = 'mipmap/ic_launcher',
    this.androidShowNotificationBadge = false,
    this.androidNotificationClickStartsActivity = true,
    this.androidNotificationOngoing = false,
    this.androidStopForegroundOnPause = true,
    this.artDownscaleWidth,
    this.artDownscaleHeight,
    this.fastForwardInterval = const Duration(seconds: 10),
    this.rewindInterval = const Duration(seconds: 10),
    this.preloadArtwork = false,
    this.androidBrowsableRootExtras,
  });
}
