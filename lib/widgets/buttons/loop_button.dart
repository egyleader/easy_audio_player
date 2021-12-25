import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class LoopButton extends StatelessWidget {
  const LoopButton({Key? key, required this.player}) : super(key: key);
  final AudioPlayer player;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LoopMode>(
      stream: player.loopModeStream,
      builder: (context, snapshot) {
        final loopMode = snapshot.data ?? LoopMode.off;
        final icons = [
          const Icon(Icons.repeat, color: Colors.grey),
          Icon(Icons.repeat, color: Theme.of(context).colorScheme.secondary),
          Icon(Icons.repeat_one, color: Theme.of(context).colorScheme.secondary),
        ];
        const cycleModes = [
          LoopMode.off,
          LoopMode.all,
          LoopMode.one,
        ];
        final index = cycleModes.indexOf(loopMode);
        return IconButton(
          icon: icons[index],
          onPressed: () {
            player.setLoopMode(cycleModes[(cycleModes.indexOf(loopMode) + 1) % cycleModes.length]);
          },
        );
      },
    );
  }
}
