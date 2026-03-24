// test/models/audio_player_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_audio_player/easy_audio_player.dart';

void main() {
  group('AudioPlayerTheme', () {
    testWidgets('resolves M3 defaults from context when no overrides provided',
        (tester) async {
      late AudioPlayerTheme resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorSchemeSeed: Colors.blue),
          home: Builder(builder: (context) {
            resolved = AudioPlayerTheme.of(context);
            return const SizedBox();
          }),
        ),
      );

      expect(resolved.primaryColor, isNotNull);
      expect(resolved.backgroundColor, isNotNull);
      expect(resolved.titleStyle, isNotNull);
      expect(resolved.subtitleStyle, isNotNull);
      expect(resolved.miniArtworkSize, 48.0);
      expect(resolved.expandedArtworkSize, 240.0);
      expect(resolved.borderRadius, 12.0);
    });

    testWidgets('explicit values override M3 defaults', (tester) async {
      late AudioPlayerTheme resolved;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            resolved = AudioPlayerTheme(
              primaryColor: Colors.red,
              borderRadius: 24.0,
            ).resolve(context);
            return const SizedBox();
          }),
        ),
      );

      expect(resolved.primaryColor, Colors.red);
      expect(resolved.borderRadius, 24.0);
    });
  });
}
