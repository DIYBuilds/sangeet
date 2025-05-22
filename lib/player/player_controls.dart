import 'package:flutter/material.dart';

class PlayerControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const PlayerControls({
    super.key,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous),
          iconSize: 36,
          onPressed: onPrevious,
        ),
        IconButton(
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
          ),
          iconSize: 64,
          onPressed: onPlayPause,
        ),
        IconButton(
          icon: const Icon(Icons.skip_next),
          iconSize: 36,
          onPressed: onNext,
        ),
      ],
    );
  }
}
