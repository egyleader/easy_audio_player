library flutter_audio_player;

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

/// An easy [AudioPlayer] implementation of [JustAudio] that uses [JustAudioBackground] and [AudioSession]
/// to controle the player notification content and behaviour and provides easy widgets
/// to use an audio player without having to it from scratch every time .
///
/// Usage: 
/// for platform sepecific setup see readme
/// 1. call `initJustAudioBackground` as early as possible in the app 
/// 2. add a player widget and pass a [ConcatenatingAudioSource] playlist to it 
///   example 1. full audio player with controles , audio details ,playlist and art image 
///         Scaffold(
///         body: SafeArea(
///             child: Padding(
///                 padding: const EdgeInsets.all(20.0),
///                 child: Center(
///                   child: FullAudioPlayer(autoPlay: false, playlist: _playlist),
///                 ))));
/// 
///   example 2. basic audio player with contorle buttons and seekbar only 
///         Scaffold(
///         body: SafeArea(
///             child: Padding(
///                 padding: const EdgeInsets.all(20.0),
///                 child: Center(
///                   child: BasicAudioPlayer(playlist: _playlist),
///                 ))));
///  
export 'services/audio_player_service.dart';
export 'package:just_audio/just_audio.dart'
    show AudioSource, HlsAudioSource, ClippingAudioSource, LoopingAudioSource, ProgressiveAudioSource, DashAudioSource;
