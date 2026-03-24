// test/widgets/player_controls_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_audio_player/easy_audio_player.dart';
import '../helpers/mock_audio_player_service.dart';

void main() {
  group('PlayerControls', () {
    late MockAudioPlayerService mockService;

    setUp(() => mockService = MockAudioPlayerService());
    tearDown(() => mockService.dispose());

    testWidgets('renders without errors with all options enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(serviceOverride: mockService),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PlayerControls), findsOneWidget);
    });

    testWidgets('hides volume when showVolume=false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(
              showVolume: false,
              serviceOverride: mockService,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.volume_up), findsNothing);
    });

    testWidgets('shows shuffle button when showShuffle=true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(showShuffle: true, serviceOverride: mockService),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.shuffle), findsOneWidget);
    });

    testWidgets('hides shuffle button when showShuffle=false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(showShuffle: false, serviceOverride: mockService),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.shuffle), findsNothing);
    });

    testWidgets('shows loop button when showLoop=true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(showLoop: true, serviceOverride: mockService),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.repeat), findsOneWidget);
    });

    testWidgets('shows speed slider when showSpeed=true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(showSpeed: true, serviceOverride: mockService),
          ),
        ),
      );
      await tester.pump();
      // Speed row shows the current speed label
      expect(find.textContaining('x'), findsOneWidget);
    });

    testWidgets('tapping play button transitions to playing state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PlayerControls(serviceOverride: mockService)),
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.play_circle_filled));
      await tester.pump();
      expect(mockService.playerState, isA<PlayerPlaying>());
    });

    testWidgets('shows replay icon when PlayerCompleted', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PlayerControls(serviceOverride: mockService)),
        ),
      );
      mockService.emitState(const PlayerCompleted());
      await tester.pump();
      expect(find.byIcon(Icons.replay), findsOneWidget);
    });
  });
}
