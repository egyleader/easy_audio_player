// test/widgets/components/control_buttons_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_audio_player/easy_audio_player.dart';
import 'package:easy_audio_player/src/widgets/components/control_buttons.dart';
import '../../helpers/mock_audio_player_service.dart';

Widget _buildWidget(
  MockAudioPlayerService service, {
  AudioPlayerTheme theme = const AudioPlayerTheme(),
  bool showShuffle = false,
  bool showLoop = false,
  bool showVolume = false,
  bool showSpeed = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ControlButtons(
        service: service,
        theme: theme,
        showShuffle: showShuffle,
        showLoop: showLoop,
        showVolume: showVolume,
        showSpeed: showSpeed,
      ),
    ),
  );
}

void main() {
  group('ControlButtons', () {
    late MockAudioPlayerService service;

    setUp(() => service = MockAudioPlayerService());
    tearDown(() => service.dispose());

    group('always-visible controls', () {
      testWidgets('shows skip_previous and skip_next icons', (tester) async {
        await tester.pumpWidget(_buildWidget(service));
        await tester.pump();
        expect(find.byIcon(Icons.skip_previous), findsOneWidget);
        expect(find.byIcon(Icons.skip_next), findsOneWidget);
      });
    });

    group('_PlayPauseButton states', () {
      testWidgets('shows play icon when idle', (tester) async {
        await tester.pumpWidget(_buildWidget(service));
        await tester.pump();
        expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
      });

      testWidgets('shows play icon when paused', (tester) async {
        service.emitState(const PlayerPaused(Duration(seconds: 10)));
        await tester.pumpWidget(_buildWidget(service));
        await tester.pump();
        expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
      });

      testWidgets('shows pause icon when playing', (tester) async {
        service.emitState(const PlayerPlaying(Duration(seconds: 5)));
        await tester.pumpWidget(_buildWidget(service));
        await tester.pump();
        expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
      });

      testWidgets('shows progress indicator when buffering', (tester) async {
        service.emitState(const PlayerBuffering());
        await tester.pumpWidget(_buildWidget(service));
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows replay icon when completed', (tester) async {
        service.emitState(const PlayerCompleted());
        await tester.pumpWidget(_buildWidget(service));
        await tester.pump();
        expect(find.byIcon(Icons.replay), findsOneWidget);
      });
    });

    group('play/pause interactions', () {
      testWidgets('tapping play transitions service to playing', (tester) async {
        await tester.pumpWidget(_buildWidget(service));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.play_circle_filled));
        await tester.pump();
        expect(service.playerState, isA<PlayerPlaying>());
        expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
      });

      testWidgets('tapping pause transitions service to paused', (tester) async {
        service.emitState(const PlayerPlaying(Duration(seconds: 5)));
        await tester.pumpWidget(_buildWidget(service));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.pause_circle_filled));
        await tester.pump();
        expect(service.playerState, isA<PlayerPaused>());
      });
    });

    group('optional controls visibility', () {
      testWidgets('hides shuffle button by default', (tester) async {
        await tester.pumpWidget(_buildWidget(service));
        await tester.pump();
        expect(find.byIcon(Icons.shuffle), findsNothing);
      });

      testWidgets('shows shuffle button when showShuffle=true', (tester) async {
        await tester.pumpWidget(_buildWidget(service, showShuffle: true));
        await tester.pump();
        expect(find.byIcon(Icons.shuffle), findsOneWidget);
      });

      testWidgets('hides loop button by default', (tester) async {
        await tester.pumpWidget(_buildWidget(service));
        await tester.pump();
        expect(find.byIcon(Icons.repeat), findsNothing);
      });

      testWidgets('shows loop button when showLoop=true', (tester) async {
        await tester.pumpWidget(_buildWidget(service, showLoop: true));
        await tester.pump();
        expect(find.byIcon(Icons.repeat), findsOneWidget);
      });

      testWidgets('hides volume row by default', (tester) async {
        await tester.pumpWidget(_buildWidget(service));
        await tester.pump();
        expect(find.byIcon(Icons.volume_up), findsNothing);
      });

      testWidgets('shows volume row when showVolume=true', (tester) async {
        await tester.pumpWidget(_buildWidget(service, showVolume: true));
        await tester.pump();
        expect(find.byIcon(Icons.volume_up), findsOneWidget);
      });

      testWidgets('hides speed row by default', (tester) async {
        await tester.pumpWidget(_buildWidget(service));
        await tester.pump();
        expect(find.textContaining('x'), findsNothing);
      });

      testWidgets('shows speed row when showSpeed=true', (tester) async {
        await tester.pumpWidget(_buildWidget(service, showSpeed: true));
        await tester.pump();
        expect(find.textContaining('x'), findsOneWidget);
      });
    });

    group('loop mode cycling', () {
      testWidgets('tapping loop cycles off → all → one → off', (tester) async {
        await tester.pumpWidget(_buildWidget(service, showLoop: true));
        await tester.pump();

        // Initial state: off — repeat icon visible
        expect(service.loopMode, EasyLoopMode.off);
        expect(find.byIcon(Icons.repeat), findsOneWidget);

        // Tap once → all
        await tester.tap(find.byIcon(Icons.repeat));
        await tester.pump();
        expect(service.loopMode, EasyLoopMode.all);

        // Tap again → one (shows repeat_one)
        await tester.tap(find.byIcon(Icons.repeat));
        await tester.pump();
        expect(service.loopMode, EasyLoopMode.one);
        expect(find.byIcon(Icons.repeat_one), findsOneWidget);

        // Tap again → off
        await tester.tap(find.byIcon(Icons.repeat_one));
        await tester.pump();
        expect(service.loopMode, EasyLoopMode.off);
      });
    });

    group('shuffle toggle', () {
      testWidgets('tapping shuffle toggles shuffle state', (tester) async {
        await tester.pumpWidget(_buildWidget(service, showShuffle: true));
        await tester.pump();

        expect(service.shuffle, isFalse);
        await tester.tap(find.byIcon(Icons.shuffle));
        await tester.pump();
        expect(service.shuffle, isTrue);

        await tester.tap(find.byIcon(Icons.shuffle));
        await tester.pump();
        expect(service.shuffle, isFalse);
      });
    });
  });
}
