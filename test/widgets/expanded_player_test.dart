// test/widgets/expanded_player_test.dart
import 'package:easy_audio_player/easy_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/mock_audio_player_service.dart';

void main() {
  group('ExpandedPlayer', () {
    late MockAudioPlayerService mockService;

    setUp(() {
      mockService = MockAudioPlayerService();
    });

    tearDown(() async {
      await mockService.dispose();
    });

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandedPlayer(serviceOverride: mockService),
          ),
        ),
      );
      expect(find.byType(ExpandedPlayer), findsOneWidget);
    });

    testWidgets('shows track title when track is emitted', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandedPlayer(serviceOverride: mockService),
          ),
        ),
      );

      mockService.emitCurrentTrack(
        AudioTrack.network(id: '1', url: 'https://x.com/t.mp3', title: 'Big Song'),
      );
      await tester.pump();
      expect(find.text('Big Song'), findsOneWidget);
    });
  });
}
