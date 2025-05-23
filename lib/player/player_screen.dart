import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sangeet/components/app_bar.dart';
import 'package:sangeet/home/home_screen.dart'; // For providers
import 'package:sangeet/home/queue_provider.dart';
import 'package:sangeet/home/youtube_music_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'player_controls.dart';
import 'volume_control.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPlayingSong = ref.watch(currentPlayingSongProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final queue = ref.watch(songQueueProvider);
    final audioPlayer = ref.watch(audioPlayerProvider);

    if (currentPlayingSong == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player')),
        body: const Center(child: Text('No song selected')),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 70),
        child: SimpleAppbar(
          showSearchBar: false,
          title: currentPlayingSong['title'] ?? 'Player',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      // appBar: AppBar(
      //   title: Text(currentPlayingSong['title'] ?? 'Player'),
      // ),
      body: Column(
        children: [
          // Album Art / Song Details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                currentPlayingSong['thumbnailUrl'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.network(
                          currentPlayingSong['thumbnailUrl'].toString(),
                          height: 200,
                          width: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.music_note, size: 200),
                        ),
                      )
                    : const Icon(Icons.music_note, size: 200),
                const SizedBox(height: 16),
                Text(
                  currentPlayingSong['title'] ?? 'Unknown Title',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                Text(
                  currentPlayingSong['artist'] ?? 'Unknown Artist',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Player Controls
          PlayerControls(
            isPlaying: isPlaying,
            onPlayPause: () {
              if (isPlaying) {
                audioPlayer.pause();
              } else {
                audioPlayer.resume();
              }
            },
            onNext: () {
              final nextSong = ref
                  .read(songQueueProvider.notifier)
                  .getNextSong();
              if (nextSong != null) {
                // Accessing _playSong directly is not ideal here.
                // This logic should be centralized.
                // For now, we'll call a simplified version or trigger it via provider.
                // This will be refactored.
                _playSongFromQueue(ref, nextSong, audioPlayer);
                ref.read(songQueueProvider.notifier).playNextSong();
              }
            },
            onPrevious: () {
              // Implement previous song logic (e.g., from history or restart current)
              // For now, just restart current song or play from start of queue if no history
              if (audioPlayer.state == PlayerState.playing ||
                  audioPlayer.state == PlayerState.paused) {
                audioPlayer.seek(Duration.zero);
                if (!isPlaying) audioPlayer.resume();
              }
            },
          ),

          // Volume Control
          const VolumeControl(),

          // Queue List
          const Expanded(child: _PlayerScreenQueueView()),
        ],
      ),
    );
  }

  // Temporary playback logic, to be refactored
  void _playSongFromQueue(
    WidgetRef ref,
    Map<String, dynamic> song,
    AudioPlayer audioPlayer,
  ) async {
    final ytExplode = ref.read(
      youtubeExplodeProvider,
    ); // Assuming youtubeExplodeProvider is accessible
    final songId = song['id'] as String;
    try {
      var manifest = await ytExplode.videos.streamsClient.getManifest(songId);
      var streamInfo = manifest.audioOnly.withHighestBitrate();
      final urlString = streamInfo.url.toString();
      if (urlString.isNotEmpty) {
        await audioPlayer.play(UrlSource(urlString));
        ref.read(playingSongIdProvider.notifier).state = songId;
        ref.read(currentPlayingSongProvider.notifier).state = song;
      } else {
        print('Error: Audio stream URL is empty for songId: $songId');
      }
    } catch (e) {
      print('Error setting audio source for $songId: $e');
    }
  }
}

class _PlayerScreenQueueView extends ConsumerWidget {
  const _PlayerScreenQueueView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(songQueueProvider);
    final audioPlayer = ref.watch(audioPlayerProvider);

    if (queue.isEmpty) {
      return const Center(child: Text('Queue is empty'));
    }

    return ReorderableListView.builder(
      itemCount: queue.length,
      itemBuilder: (context, index) {
        final song = queue[index];
        return ListTile(
          key: ValueKey(song['id']),
          leading: song['thumbnailUrl'] != null
              ? Image.network(
                  song['thumbnailUrl'].toString(),
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                )
              : const Icon(Icons.music_note, size: 40),
          title: Text(
            song['title'] ?? 'Unknown Title',
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            song['artist'] ?? 'Unknown Artist',
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () =>
                ref.read(songQueueProvider.notifier).removeSong(song['id']),
          ),
          onTap: () {
            // Play this song from queue
            ref.read(songQueueProvider.notifier).reorderQueue(index, 0);
            final nextSong = ref.read(songQueueProvider.notifier).getNextSong();
            if (nextSong != null) {
              // This logic should be centralized.
              _playSongFromQueueInList(ref, nextSong, audioPlayer);
              ref.read(songQueueProvider.notifier).playNextSong();
            }
          },
        );
      },
      onReorder: (oldIndex, newIndex) {
        ref.read(songQueueProvider.notifier).reorderQueue(oldIndex, newIndex);
      },
    );
  }

  // Temporary playback logic, to be refactored
  void _playSongFromQueueInList(
    WidgetRef ref,
    Map<String, dynamic> song,
    AudioPlayer audioPlayer,
  ) async {
    final ytExplode = ref.read(
      youtubeExplodeProvider,
    ); // Assuming youtubeExplodeProvider is accessible
    final songId = song['id'] as String;
    try {
      var manifest = await ytExplode.videos.streamsClient.getManifest(songId);
      var streamInfo = manifest.audioOnly.withHighestBitrate();
      final urlString = streamInfo.url.toString();
      if (urlString.isNotEmpty) {
        await audioPlayer.play(UrlSource(urlString));
        ref.read(playingSongIdProvider.notifier).state = songId;
        ref.read(currentPlayingSongProvider.notifier).state = song;
      } else {
        print('Error: Audio stream URL is empty for songId: $songId');
      }
    } catch (e) {
      print('Error setting audio source for $songId: $e');
    }
  }
}
