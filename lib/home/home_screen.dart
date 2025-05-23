import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart'; // Import audioplayers
import 'package:sangeet/components/app_bar.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:window_manager/window_manager.dart';
import 'youtube_music_provider.dart';
import 'search_provider.dart'; // Import search provider
import 'queue_provider.dart'; // Import queue provider
import 'package:sangeet/player/player_screen.dart'; // Import PlayerScreen
import 'package:sangeet/services/audio_service.dart'; // Import AudioService

// Provider for the AudioPlayer instance
final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  // Configure player for Windows - this is often default or handled by the plugin
  // player.setReleaseMode(ReleaseMode.stop); // Example, default is usually fine
  ref.onDispose(() {
    player.dispose(); // Dispose the player when the provider is disposed
  });
  return player;
});

// Provider to keep track of the currently playing song's ID
final playingSongIdProvider = StateProvider<String?>((ref) => null);
// Provider to store the details of the currently playing song
final currentPlayingSongProvider = StateProvider<Map<String, dynamic>?>(
  (ref) => null,
);

// Provider to track playback state (playing/paused)
final isPlayingProvider = StateProvider<bool>((ref) => false);

// Provider to track if a song is currently being loaded (moved from audio_service.dart for broader use if needed)
final isLoadingSongProvider = StateProvider<bool>((ref) => false);

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsyncValue = ref.watch(youtubeMusicLibraryProvider);
    final searchResultsAsyncValue = ref.watch(searchMusicProvider);
    final audioPlayer = ref.watch(audioPlayerProvider);
    final playingSongId = ref.watch(playingSongIdProvider);
    final currentPlayingSong = ref.watch(currentPlayingSongProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final queue = ref.watch(songQueueProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final isLoadingSong = ref.watch(
      isLoadingSongProvider,
    ); // Watch loading state

    // Listen to player state changes to update isPlayingProvider
    audioPlayer.onPlayerStateChanged.listen((state) {
      if (ref.read(playingSongIdProvider) != null) {
        ref.read(isPlayingProvider.notifier).state =
            state == PlayerState.playing;
      }
    });

    // Listen for when the song completes
    audioPlayer.onPlayerComplete.listen((_) {
      if (ref.read(playingSongIdProvider) != null) {
        ref.read(isPlayingProvider.notifier).state = false;
        // ref.read(currentPlayingSongProvider.notifier).state = null; // Keep current song for the player screen until next song plays
        ref.read(audioServiceProvider).playNextFromQueue();
      }
    });

    final songsToList = searchQuery.trim().isEmpty
        ? songsAsyncValue
        : searchResultsAsyncValue;

    return GestureDetector(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 70),
          child: SimpleAppbar(title: 'Sangeet'),
        ),
        body: Column(
          children: [
            Expanded(
              child: songsToList.when(
                data: (songs) {
                  if (songs.isEmpty) {
                    return Center(
                      child: Text(
                        searchQuery.trim().isEmpty
                            ? 'No songs found or error fetching.'
                            : 'No results for "$searchQuery"',
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final songId = song['id'] as String;
                      final isCurrentlyPlayingFromList =
                          songId == playingSongId && isPlaying;
                      final isLoadingThisSong =
                          isLoadingSong &&
                          playingSongId ==
                              songId; // Check if this specific song is loading

                      return ListTile(
                        leading: song['thumbnailUrl'] != null
                            ? SizedBox(
                                width: 50,
                                height: 50,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    song['thumbnailUrl']
                                        .toString(), // Ensure it's a string
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.music_note),
                                  ),
                                ),
                              )
                            : const Icon(Icons.music_note, size: 50),
                        title: Text(song['title'] ?? 'Unknown Title'),
                        subtitle: Text(song['artist'] ?? 'Unknown Artist'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.playlist_add),
                              onPressed: () {
                                ref
                                    .read(songQueueProvider.notifier)
                                    .addSong(song);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Added "${song['title']}" to queue',
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                isCurrentlyPlayingFromList
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                              ),
                              iconSize: 30,
                              onPressed: isLoadingThisSong
                                  ? null // Disable button if this song is loading
                                  : () => ref
                                        .read(audioServiceProvider)
                                        .playSong(song, context: context),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
            if (currentPlayingSong != null)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PlayerScreen(),
                    ),
                  );
                },
                child: _NowPlayingBar(
                  song: currentPlayingSong,
                  isPlaying: isPlaying,
                  isLoading:
                      isLoadingSong &&
                      playingSongId == currentPlayingSong['id'],
                ), // Pass loading state
              ),
            if (queue.isNotEmpty &&
                currentPlayingSong ==
                    null) // Show queue only if nothing is playing or if player screen is not primary focus
              _SongQueueView(),
          ],
        ),
      ),
    );
  }

  // _playSong method is now part of AudioService
}

class _NowPlayingBar extends ConsumerWidget {
  final Map<String, dynamic> song;
  final bool isPlaying;
  final bool isLoading; // Add isLoading state

  const _NowPlayingBar({
    required this.song,
    required this.isPlaying,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioPlayer = ref.watch(audioPlayerProvider);
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        boxShadow: const [
          BoxShadow(
            blurRadius: 2,
            color: Colors.black12,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          song['thumbnailUrl'] != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: Image.network(
                    song['thumbnailUrl'].toString(), // Ensure it's a string
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(Icons.music_note, size: 40),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  song['title'] ?? 'Unknown Title',
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song['artist'] ?? 'Unknown Artist',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: isLoading
                ? null
                : () {
                    if (isPlaying) {
                      audioPlayer.pause();
                    } else {
                      audioPlayer.resume();
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class _SongQueueView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(songQueueProvider);
    if (queue.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 150, // Adjust height as needed
      constraints: const BoxConstraints(maxHeight: 200), // Add maxHeight
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Up Next', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () =>
                      ref.read(songQueueProvider.notifier).clearQueue(),
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: queue.length,
              itemBuilder: (context, index) {
                final song = queue[index];
                return ListTile(
                  key: ValueKey(song['id']),
                  leading: song['thumbnailUrl'] != null
                      ? Image.network(
                          song['thumbnailUrl']
                              .toString(), // Ensure it's a string
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.music_note, size: 30),
                  title: Text(
                    song['title'] ?? 'Unknown Title',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () => ref
                        .read(songQueueProvider.notifier)
                        .removeSong(song['id']),
                  ),
                  onTap: () {
                    // Play this song from queue and re-order
                    final selectedSong = queue[index];
                    ref.read(songQueueProvider.notifier).reorderQueue(index, 0);
                    // The playNextFromQueue will pick the top one after reorder
                    ref
                        .read(audioServiceProvider)
                        .playSong(selectedSong, context: context);
                    // No need to call playNextSong from queue provider here, as playSong handles it if it's a new song.
                    // If it was already playing and paused, playSong will resume.
                  },
                );
              },
              onReorder: (oldIndex, newIndex) {
                ref
                    .read(songQueueProvider.notifier)
                    .reorderQueue(oldIndex, newIndex);
              },
            ),
          ),
        ],
      ),
    );
  }
}
