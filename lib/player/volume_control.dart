import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sangeet/home/home_screen.dart'; // For audioPlayerProvider

// Provider for current volume
final volumeProvider = StateProvider<double>((ref) => 1.0);

class VolumeControl extends ConsumerWidget {
  const VolumeControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioPlayer = ref.watch(audioPlayerProvider);
    final currentVolume = ref.watch(volumeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.volume_down),
          Expanded(
            child: Slider(
              value: currentVolume,
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                audioPlayer.setVolume(value);
                ref.read(volumeProvider.notifier).state = value;
              },
            ),
          ),
          const Icon(Icons.volume_up),
        ],
      ),
    );
  }
}
