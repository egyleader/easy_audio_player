## 1.0.0

* First stable release.
* `MiniPlayer`, `ExpandedPlayer`, `PlayerControls` widgets with Material 3 adaptive theming.
* Background playback with lock-screen notification controls via `just_audio_background`.
* Playlist management: load, add, remove, reorder, shuffle, loop.
* Waveform visualization (Android, iOS, macOS) via `just_waveform`.
* Headless mode via `EasyAudioPlayer.service` for custom UIs.
* `AudioTrack.network` and `AudioTrack.file` constructors.
* BehaviorSubject-backed streams: `playerStateStream`, `currentTrackStream`, `positionStream`, `queueStream`, `errorStream`.
* Auto-skip on track error with `errorStream` emission.

## 0.0.1

* Initial release.
* Added audio player widgets.
