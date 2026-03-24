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
  });
}
