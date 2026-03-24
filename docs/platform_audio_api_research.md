# Flutter Audio Player: Platform Audio API Research
# Generated: 2026-03-24

---

## 1. Android Audio Permissions & APIs by Version

### Permissions Required for Playback (API 21 → 35)

**Foreground Playback (all versions):**
- `WAKE_LOCK` — prevents CPU sleep during playback (MediaPlayer/ExoPlayer request this internally)
- `INTERNET` — for streaming audio
- No special audio playback permission required

**Background Playback:**
- API 21+: `FOREGROUND_SERVICE` — required to call `startForeground()`
- API 33 (Android 13): `POST_NOTIFICATIONS` — runtime permission required; without it the media notification is silently not shown
- API 34 (Android 14): `FOREGROUND_SERVICE_MEDIA_PLAYBACK` — typed foreground service permission required

**Bluetooth Audio:**
- API 31+: `BLUETOOTH_CONNECT` required to enumerate/connect Bluetooth audio devices

---

### AudioFocusRequest — API 26 vs Legacy

**Legacy API (API 21–25, still works but deprecated):**
```java
AudioManager.requestAudioFocus(
    AudioFocusChangeListener listener,
    int streamType,         // AudioManager.STREAM_MUSIC
    int durationHint        // AUDIOFOCUS_GAIN / AUDIOFOCUS_GAIN_TRANSIENT / etc.
)
```

**New API — AudioFocusRequest (introduced API 26 / Android 8.0 Oreo):**
```java
AudioFocusRequest request = new AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
    .setAudioAttributes(new AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
        .build())
    .setOnAudioFocusChangeListener(listener)
    .setWillPauseWhenDucked(false)   // added API 28
    .build();
AudioManager.requestAudioFocus(request);  // returns AUDIOFOCUS_REQUEST_GRANTED/FAILED/DELAYED
```

Key differences:
- Structured `AudioAttributes` instead of raw stream type
- `setWillPauseWhenDucked(true)` — system calls your listener instead of auto-ducking (API 28+)
- Builder pattern; reusable request object for `abandonAudioFocusRequest()`
- Returns `AUDIOFOCUS_REQUEST_DELAYED` (new) when another app has temporary focus

**Focus change callbacks (all versions):**
- `AUDIOFOCUS_LOSS` → stop/release player
- `AUDIOFOCUS_LOSS_TRANSIENT` → pause
- `AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK` → reduce volume or pause
- `AUDIOFOCUS_GAIN` → resume/restore volume

---

### MediaSession API Evolution

**MediaSession (android.media.session.MediaSession) — API 21+:**
- Platform class, native
- Use `MediaMetadata` (not Compat), `PlaybackState`
- Direct lock screen integration

**MediaSessionCompat (AndroidX) — API 21+:**
- Backward-compatible wrapper around `MediaSession`
- Use `setMetadata(MediaMetadataCompat)`, `setPlaybackState(PlaybackStateCompat)`
- Connect via `MediaControllerCompat`
- Still fully supported, widely used in non-Media3 stacks

**MediaSession2 / MediaController2 — API 29:**
- Introduced in Android 10 but largely superseded by Media3
- Not widely adopted; skip in favor of Media3

**Media3 MediaSession (androidx.media3.session) — stable since April 2023:**
- `androidx.media3.session.MediaSession` wraps an ExoPlayer instance
- `MediaSessionService` replaces `MediaBrowserServiceCompat` pattern
- `MediaController` connects to `MediaSessionService` via `SessionToken`
- Handles notification, foreground service lifecycle automatically
- **Recommended approach for new development**

---

### MediaMetadataCompat vs MediaMetadata

| | MediaMetadataCompat | androidx.media3.common.MediaMetadata |
|---|---|---|
| Use with | MediaSessionCompat | Media3 MediaSession / ExoPlayer |
| Key style | `METADATA_KEY_TITLE`, `METADATA_KEY_ARTIST` | Builder: `.setTitle()`, `.setArtist()` |
| Artwork | `METADATA_KEY_ALBUM_ART` (Bitmap) | `.setArtworkUri()` or `.setArtworkData()` |
| Attached to | `MediaSessionCompat.setMetadata()` | `MediaItem.Builder().setMediaMetadata().build()` |

**Recommendation:** Use `androidx.media3.common.MediaMetadata` with Media3.

---

### POST_NOTIFICATIONS — Android 13 / API 33

- `android.permission.POST_NOTIFICATIONS` is a **runtime permission** starting API 33
- Must be declared in `AndroidManifest.xml`
- Must be requested at runtime via `ActivityCompat.requestPermissions()`
- On API < 33: permission auto-granted, no runtime request needed
- On API 33+ without permission: notification is silently not displayed (no crash)
- Media3's `MediaSessionService` still runs but the notification won't appear
- Handle gracefully: check `Build.VERSION.SDK_INT >= 33` before requesting

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

```kotlin
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
    ActivityCompat.requestPermissions(this,
        arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_CODE)
}
```

---

### FOREGROUND_SERVICE_MEDIA_PLAYBACK — Android 14 / API 34

Starting API 34, foreground services **must** declare a specific type.

**Manifest changes required:**
```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>

<service
    android:name=".PlaybackService"
    android:foregroundServiceType="mediaPlayback"
    android:exported="true"/>
```

**Service code:**
```kotlin
// API 34+: must pass serviceType
ServiceCompat.startForeground(
    this,
    NOTIFICATION_ID,
    notification,
    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
)
```

Media3's `MediaSessionService` handles this automatically when you declare `foregroundServiceType="mediaPlayback"` in the manifest.

**On API < 34:** `FOREGROUND_SERVICE` alone suffices; `foregroundServiceType` in manifest is harmless on older APIs.

---

### ExoPlayer → Media3 Migration

**Old (deprecated):**
- `com.google.android.exoplayer2.*`
- `SimpleExoPlayer`
- `MediaSessionConnector`
- `PlayerNotificationManager`
- `ConcatenatingMediaSource` for playlists

**New (Media3):**
- `androidx.media3.exoplayer:exoplayer`
- `androidx.media3.session:media3-session`
- `androidx.media3.common:media3-common`
- `ExoPlayer` (interface replaces `SimpleExoPlayer`)
- `MediaSession` natively bridges player ↔ system (no connector needed)
- `MediaNotification.Provider` / `DefaultMediaNotificationProvider`
- `player.addMediaItem()` / `player.addMediaItems()` for playlists
- Stable since 1.0.0 (April 2023); current releases: 1.3.x / 1.4.x
- Minimum SDK: API 21

**Media3 background service pattern:**
```kotlin
class PlaybackService : MediaSessionService() {
    private lateinit var player: ExoPlayer
    private lateinit var mediaSession: MediaSession

    override fun onCreate() {
        player = ExoPlayer.Builder(this).build()
        mediaSession = MediaSession.Builder(this, player).build()
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo) = mediaSession

    override fun onDestroy() {
        mediaSession.release(); player.release(); super.onDestroy()
    }
}
```

---

### AudioManager Behavior Differences by Version

| API | Change |
|-----|--------|
| 21 | `requestAudioFocus(listener, streamType, durationHint)` |
| 26 | `requestAudioFocus(AudioFocusRequest)` — new structured API |
| 26 | Background execution limits; must use `startForegroundService()` |
| 26 | Notification channels required |
| 28 | `AudioFocusRequest.setWillPauseWhenDucked()` |
| 29 | Background activity start restrictions tightened |
| 31 | Notification trampoline restrictions (PendingIntent flags) |
| 33 | `POST_NOTIFICATIONS` runtime permission |
| 33 | Media controls redesigned in Quick Settings |
| 34 | Typed `foregroundServiceType="mediaPlayback"` mandatory |
| 35 | Predictive back enforcement; foreground service constraints continued |

---

## 2. iOS Audio Session & Background Modes

### AVAudioSession Categories

| Category | Silenced by Ring/Silent Switch | Silenced on Lock | Mixes with Others | Use Case |
|----------|-------------------------------|------------------|-------------------|----------|
| `.ambient` | Yes | Yes | Yes | Non-critical audio, games |
| `.soloAmbient` | Yes | Yes | No | Default; casual playback |
| `.playback` | **No** | **No** | No (default) | **Audio players** |
| `.record` | No | No | No | Recording only |
| `.playAndRecord` | No | No | No | VoIP, voice messages |

**For audio players: `.playback` is mandatory for background audio.**

### AVAudioSession Modes (used with `.playback`)

- `.default` — standard music/podcast player
- `.spokenAudio` — signals to other apps this is speech content; enables speech-aware ducking (podcasts, audiobooks)
- `.moviePlayback` — optimizes for video audio

### Background Audio

Required in `Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

Or in Xcode: Signing & Capabilities → Background Modes → "Audio, AirPlay, and Picture in Picture"

No runtime permission required (unlike Android).

### Setup Code

```swift
do {
    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
    try AVAudioSession.sharedInstance().setActive(true)
} catch {
    print("AVAudioSession setup failed: \(error)")
}
```

### Interruption Handling

```swift
NotificationCenter.default.addObserver(
    forName: AVAudioSession.interruptionNotification,
    object: nil, queue: .main
) { notification in
    guard let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
    switch type {
    case .began:
        // Pause — system has deactivated your audio session
    case .ended:
        // Check shouldResume flag before resuming
        let options = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
        if AVAudioSession.InterruptionOptions(rawValue: options ?? 0).contains(.shouldResume) {
            // Resume playback
        }
    }
}

// Headphone unplug
NotificationCenter.default.addObserver(
    forName: AVAudioSession.routeChangeNotification,
    object: nil, queue: .main
) { notification in
    if let reason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
       AVAudioSession.RouteChangeReason(rawValue: reason) == .oldDeviceUnavailable {
        // Pause — headphones disconnected
    }
}
```

### iOS Version-Specific Changes

- **iOS 13:** `NowPlayable` protocol introduced — formalizes `MPNowPlayingInfoCenter` integration; more relevant for tvOS/macOS; iOS handles most automatically without it
- **iOS 16:** `AVAudioSession.prefersInterruptionHandlingMode` — CarPlay-specific
- **iOS 17:** `AVAudioSession.renderingMode` added (spatial audio); interruption notifications now fire more reliably for Siri interactions
- **iOS 18:** No breaking audio session changes documented

---

### MPNowPlayingInfoCenter

Set on every track change:
```swift
var nowPlayingInfo = [String: Any]()
nowPlayingInfo[MPMediaItemPropertyTitle] = "Track Title"
nowPlayingInfo[MPMediaItemPropertyArtist] = "Artist Name"
nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Album"
nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration  // TimeInterval
nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime  // TimeInterval
nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0  // 0.0 = paused
nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = false
nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue

// Artwork
let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork

MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
```

Update `MPNowPlayingInfoPropertyElapsedPlaybackTime` on seek; system auto-advances display using `playbackRate`.

---

### MPRemoteCommandCenter

```swift
let center = MPRemoteCommandCenter.shared()

// Enable and handle commands
center.playCommand.isEnabled = true
center.playCommand.addTarget { _ in self.play(); return .success }

center.pauseCommand.isEnabled = true
center.pauseCommand.addTarget { _ in self.pause(); return .success }

center.togglePlayPauseCommand.isEnabled = true  // headphone single-tap
center.togglePlayPauseCommand.addTarget { _ in self.togglePlayPause(); return .success }

center.nextTrackCommand.isEnabled = true
center.nextTrackCommand.addTarget { _ in self.nextTrack(); return .success }

center.previousTrackCommand.isEnabled = true
center.previousTrackCommand.addTarget { _ in self.previousTrack(); return .success }

// Seek to position
center.changePlaybackPositionCommand.isEnabled = true
center.changePlaybackPositionCommand.addTarget { event in
    let e = event as! MPChangePlaybackPositionCommandEvent
    self.seek(to: e.positionTime)
    return .success
}

// Skip forward/backward by interval
center.skipForwardCommand.isEnabled = true
center.skipForwardCommand.preferredIntervals = [15]
center.skipForwardCommand.addTarget { event in
    let e = event as! MPSkipIntervalCommandEvent
    self.seek(by: e.interval)
    return .success
}
```

Available commands: `playCommand`, `pauseCommand`, `stopCommand`, `togglePlayPauseCommand`, `nextTrackCommand`, `previousTrackCommand`, `skipForwardCommand`, `skipBackwardCommand`, `seekForwardCommand`, `seekBackwardCommand`, `changePlaybackPositionCommand`, `changePlaybackRateCommand`, `likeCommand`, `dislikeCommand`, `bookmarkCommand`, `ratingCommand`

---

### CarPlay

- Requires `com.apple.developer.carplay-audio` entitlement
- Uses `CPTemplateApplicationAudioSceneSessionRoleApplication`
- `MPNowPlayingInfoCenter` display is automatic in CarPlay
- `MPRemoteCommandCenter` controls work in CarPlay without extra code
- `AVAudioSession.prefersInterruptionHandlingMode` (iOS 16+) for CarPlay-aware interruption behavior

### AirPlay / AirPlay 2

- `AVPlayer.allowsExternalPlayback = true` enables AirPlay
- `AVRoutePickerView` for in-app route selection UI
- `MPNowPlayingInfoCenter` metadata propagates to AirPlay 2 receivers automatically
- AirPlay 2 multi-room sync: `AVSampleBufferAudioRenderer` for low-level control
- No special permission required

---

## 3. Cross-Platform Differences

### Audio Focus

| Aspect | Android | iOS |
|--------|---------|-----|
| API | Explicit: `AudioManager.requestAudioFocus()` | Implicit: `AVAudioSession.setActive(true)` |
| Focus types | `AUDIOFOCUS_GAIN`, `AUDIOFOCUS_GAIN_TRANSIENT`, `AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK` | None; category determines behavior |
| Focus callbacks | `onAudioFocusChange()` with loss/gain/duck events | `interruptionNotification` (.began / .ended) |
| Ducking | Explicit duck (lower volume) or `setWillPauseWhenDucked()` | System-controlled; `.spokenAudio` mode enables speech-aware ducking |
| Release | `abandonAudioFocusRequest()` | `AVAudioSession.setActive(false, options: .notifyOthersOnDeactivation)` |
| Headphone unplug | `AudioManager.ACTION_AUDIO_BECOMING_NOISY` broadcast | `AVAudioSession.routeChangeNotification` |

### Lock Screen Controls

| Aspect | Android | iOS |
|--------|---------|-----|
| Mechanism | `MediaStyle` notification | `MPNowPlayingInfoCenter` + `MPRemoteCommandCenter` |
| Permission required | `POST_NOTIFICATIONS` (API 33+) | None |
| Metadata | `MediaMetadata` / `MediaMetadataCompat` set on `MediaSession` | `MPNowPlayingInfoCenter.default().nowPlayingInfo` dictionary |
| Commands | `MediaSession.Callback` / `MediaController` | `MPRemoteCommandCenter` target handlers |
| Quick Settings | Shown in media controls tile (Android 13+) | Shown in Control Center automatically |

### Notification/Widget Behavior

| Aspect | Android | iOS |
|--------|---------|-----|
| Notification type | `MediaStyle` notification (app-managed) | System-managed now-playing UI |
| Dismissible | Yes — app must handle service stop | N/A — not a notification |
| Foreground service | Required for background (API 26+) | Not applicable |
| Typed service | `foregroundServiceType="mediaPlayback"` (API 34+) | Not applicable |
| API 33+ permission | `POST_NOTIFICATIONS` runtime request | Not required |

### Flutter Package Implications

For a complete audio player package supporting background playback and system controls:

**Android side needs:**
1. A `Service` (extend `MediaSessionService` with Media3, or custom `Service`)
2. `MediaSession` (Media3) connected to `ExoPlayer`
3. `MediaStyle` notification via `DefaultMediaNotificationProvider`
4. Manifest: `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_MEDIA_PLAYBACK` (API 34) + `POST_NOTIFICATIONS` (API 33)
5. `foregroundServiceType="mediaPlayback"` on the service element
6. Runtime request for `POST_NOTIFICATIONS` on API 33+ devices

**iOS side needs:**
1. `AVAudioSession` configured with `.playback` category before playback starts
2. `UIBackgroundModes: [audio]` in `Info.plist`
3. `MPNowPlayingInfoCenter` updated on every track change and seek
4. `MPRemoteCommandCenter` handlers registered for play/pause/skip/seek
5. `interruptionNotification` observer for phone calls/Siri
6. `routeChangeNotification` observer for headphone unplug

**Reference packages (how others solve this):**
- `just_audio` + `audio_service` — separates playback from background/system integration
- `audio_service` uses an isolate-based background handler on iOS and a foreground service on Android
