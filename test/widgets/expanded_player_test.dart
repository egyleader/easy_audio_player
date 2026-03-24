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

    testWidgets('shows non-current tracks in playlist when showPlaylist=true', (tester) async {
      // Load two tracks — Track A becomes the current track (shown in header),
      // Track B only appears via the playlist view.
      await mockService.load([
        AudioTrack.network(id: '1', url: 'https://x.com/a.mp3', title: 'Track A'),
        AudioTrack.network(id: '2', url: 'https://x.com/b.mp3', title: 'Track B'),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandedPlayer(showPlaylist: true, serviceOverride: mockService),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Track B'), findsOneWidget);
    });

    testWidgets('does not show non-current tracks when showPlaylist=false', (tester) async {
      // Track A is current (shown in header), Track B only appears via playlist.
      await mockService.load([
        AudioTrack.network(id: '1', url: 'https://x.com/a.mp3', title: 'Track A'),
        AudioTrack.network(id: '2', url: 'https://x.com/b.mp3', title: 'Track B'),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandedPlayer(showPlaylist: false, serviceOverride: mockService),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Track B'), findsNothing);
    });
  });
}
