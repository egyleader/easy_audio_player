// example/lib/data/sample_tracks.dart
import 'package:easy_audio_player/easy_audio_player.dart';

/// Sample tracks used across all example screens.
/// Mix of network, asset, and an intentionally broken URL for error demos.
final sampleTracks = [
  AudioTrack.network(
    id: 'track_1',
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    title: 'SoundHelix Song 1',
    artist: 'SoundHelix',
    album: 'Sample Album',
    artworkUrl: 'https://picsum.photos/seed/track1/300/300',
    extras: {'genre': 'Electronic'},
  ),
  AudioTrack.network(
    id: 'track_2',
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    title: 'SoundHelix Song 2',
    artist: 'SoundHelix',
    album: 'Sample Album',
    artworkUrl: 'https://picsum.photos/seed/track2/300/300',
  ),
  AudioTrack.asset(
    id: 'track_asset',
    assetPath: 'assets/audio/sample.mp3',
    title: 'Bundled Asset Track',
    artist: 'Local',
    album: 'Device',
    artworkUrl: 'https://picsum.photos/seed/asset/300/300',
  ),
  AudioTrack.network(
    id: 'track_3',
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    title: 'SoundHelix Song 3',
    artist: 'SoundHelix',
    album: 'Sample Album',
    artworkUrl: 'https://picsum.photos/seed/track3/300/300',
  ),
];

/// A broken track used in the Features screen to demonstrate error handling.
final brokenTrack = AudioTrack.network(
  id: 'track_broken',
  url: 'https://example.com/this-file-does-not-exist.mp3',
  title: 'Broken Track (404)',
  artist: 'Error Demo',
  artworkUrl: 'https://picsum.photos/seed/broken/300/300',
);
