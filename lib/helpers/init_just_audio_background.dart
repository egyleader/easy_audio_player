import 'dart:developer';

import 'package:easy_audio_player/models/models.dart';
import 'package:just_audio_background/just_audio_background.dart';

Future<void> initJustAudioBackground(NotificationSettings notificationSettings) async => await JustAudioBackground.init(
      androidResumeOnClick: notificationSettings.androidResumeOnClick,
      androidNotificationChannelId: notificationSettings.androidNotificationChannelId,
      androidNotificationChannelName: notificationSettings.androidNotificationChannelName,
      androidNotificationChannelDescription: notificationSettings.androidNotificationChannelDescription,
      notificationColor: notificationSettings.notificationColor,
      androidNotificationIcon: notificationSettings.androidNotificationIcon,
      androidShowNotificationBadge: notificationSettings.androidShowNotificationBadge,
      androidNotificationClickStartsActivity: notificationSettings.androidNotificationClickStartsActivity,
      androidNotificationOngoing: notificationSettings.androidNotificationOngoing,
      androidStopForegroundOnPause: notificationSettings.androidStopForegroundOnPause,
      artDownscaleWidth: notificationSettings.artDownscaleWidth,
      artDownscaleHeight: notificationSettings.artDownscaleHeight,
      fastForwardInterval: notificationSettings.fastForwardInterval,
      rewindInterval: notificationSettings.rewindInterval,
      preloadArtwork: notificationSettings.preloadArtwork,
      androidBrowsableRootExtras: notificationSettings.androidBrowsableRootExtras,
    ).catchError((e) => log(e));
