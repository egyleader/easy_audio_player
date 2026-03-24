// test/widgets/mini_player_test.dart
import 'package:easy_audio_player/easy_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/mock_audio_player_service.dart';

void main() {
  group('MiniPlayer', () {
    late MockAudioPlayerService mockService;

    setUp(() {
      mockService = MockAudioPlayerService();
    });

    tearDown(() async {
      await mockService.dispose();
    });

    testWidgets('renders without crashing with no track', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiniPlayer(serviceOverride: mockService),
          ),
        ),
      );
      expect(find.byType(MiniPlayer), findsOneWidget);
    });

    testWidgets('shows track title when a track is emitted', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiniPlayer(serviceOverride: mockService),
          ),
        ),
      );

      mockService.emitCurrentTrack(
        AudioTrack.network(id: '1', url: 'https://x.com/t.mp3', title: 'Test Song'),
      );
      await tester.pump();
      expect(find.text('Test Song'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiniPlayer(
              serviceOverride: mockService,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(MiniPlayer));
      expect(tapped, isTrue);
    });
  });
}
