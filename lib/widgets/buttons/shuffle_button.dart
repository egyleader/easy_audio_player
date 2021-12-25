import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class ShuffleButton extends StatelessWidget {
  const ShuffleButton({Key? key, required this.player}) : super(key: key);
  final AudioPlayer player;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: player.shuffleModeEnabledStream,
      builder: (context, snapshot) {
        final shuffleModeEnabled = snapshot.data ?? false;
        return IconButton(
          icon: shuffleModeEnabled
              ? const Icon(Icons.shuffle, color: Colors.orange)
              : const Icon(Icons.shuffle, color: Colors.grey),
          onPressed: () async {
            final enable = !shuffleModeEnabled;
            if (enable) {
              await player.shuffle();
            }
            await player.setShuffleModeEnabled(enable);
          },
        );
      },
    );
  }
}
